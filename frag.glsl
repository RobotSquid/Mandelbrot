#version 400

#define PREC 4
#define ITER 250
#define RATE 0.02

#define sqrcf(v) dvec2(v.x*v.x-v.y*v.y, v.x*v.y*2)
#define pytcf(v) v.x*v.x+v.y*v.y

uniform int frame;

out vec4 fragColor;

vec4 ramp(int i) {
    float normalized_mod = mod(float(i), 50.0) / 50.0;
	float normalized_cos = (cos(normalized_mod * 2.0 * 3.14159265358) + 1.0) * 0.5;
    i = int(50.0 * normalized_cos);
    float factor = float(i) / 50.0;
    float inverse_factor = 1.0 - factor;
    return vec4(sqrt(sqrt(factor)), factor, inverse_factor * 0.5, 1.0);
}

vec4 color(dvec2 z, int i) {
    float s = float(i) + log2(log(200000.0)) - log2(log(float(length(z))));
    s *= 2;
    int first = int(floor(s));
    return ramp(first)*(1.0-s+float(first)) + ramp(first+1)*(s-float(first));
}

struct big {
    uint d[PREC];
    bool p;
};

bool agtr(big a, big b) {
    for (int i = PREC-1; i >= 0; i--) {
        if (a.d[i] > b.d[i]) return true;
        if (a.d[i] < b.d[i]) return false;
    }
    return false;
}

big addxx(big a, big b) {
    uint d[PREC];
    big res = big(d, a.p);
    uint c1 = 0, c2;
    for (int i = 0; i < PREC; i++) {
        res.d[i] = uaddCarry(a.d[i], b.d[i], c2) + c1;
        c1 = c2;
    }
    return res;
}

big subxx(big a, big b) {
    bool flag = false;
    if (agtr(b, a)) {
        big tmp = a;
        a = b;
        b = tmp;
        flag = true;
    }
    uint d[PREC];
    big res = big(d, a.p != flag);
    uint c1 = 0, c2;
    for (int i = 0; i < PREC; i++) {
        res.d[i] = usubBorrow(a.d[i], b.d[i] + c1, c2);
        c1 = c2;
    }
    return res;
}

big addx(big a, big b) {
    if (a.p != b.p) {
        b.p = !b.p;
        return subxx(a, b);
    }
    return addxx(a, b);
}

big subx(big a, big b) {
    if (a.p != b.p) {
        b.p = !b.p;
        return addxx(a, b);
    }
    return subxx(a, b);
}

big mulx(big a, big b) {
    uint d[PREC];
    big res = big(d, a.p == b.p);
    uint msc = 0, adc = 0, msb, lsb;
    for (int j = 0; j < PREC-1; j++) {
        umulExtended(a.d[j], b.d[PREC-j-1], msb, lsb);
        msc += msb;
    }
    for (int i = 0; i < PREC; i++) {
        res.d[i] = msc;
        msc = 0;
        for (int j = i; j < PREC; j++) {
            umulExtended(a.d[j], b.d[PREC+i-j-1], msb, lsb);
            res.d[i] = uaddCarry(res.d[i], lsb, adc);
            msc += msb + adc;
        }
    }
    return res;
}

struct cbig {
    big x;
    big y;
};

cbig sqrc(cbig v) {
    big x = mulx(v.x, v.y);
    return cbig(subx(mulx(v.x, v.x), mulx(v.y, v.y)), addx(x, x));
}

cbig addc(cbig a, cbig b) {
    return cbig(addx(a.x, b.x), addx(a.y, b.y));
}

big sqrb(cbig v) {
    return addx(mulx(v.x, v.x), mulx(v.y, v.y));
}

big f2b(float v) {
    uint d[PREC];
    big res = big(d, v>=0);
    v = abs(v);
    for (int i = 0; i < PREC; i++) {
        res.d[PREC-i-1] = uint(v);
        if (uint(v) != 0) v = (v-uint(v))*4294967296.0;
        else v = v*4294967296.0;
    }
    return res;
}

float b2f(big b) {
    float f = 0.0;
    for (int i = 0; i < PREC; i++) {
        f += float(b.d[PREC-i-1])/pow(4294967296.0, i);
    }
    return f;
    //return (b.p ? 1 : -1)*(b.d[PREC-1] + (i == PREC-1 ? 0 : float(b.d[PREC-2])/4294967296.0));
}

big d2b(double v) {
    uint d[PREC];
    big res = big(d, v>=0);
    v = abs(v);
    for (int i = 0; i < PREC; i++) {
        res.d[PREC-i-1] = uint(v);
        if (uint(v) != 0) v = (v-uint(v))*4294967296.0;
        else v = v*4294967296.0;
    }
    return res;
}

double b2d(big b) {
    double f = 0.0;
    for (int i = 0; i < PREC; i++) {
        f += double(b.d[PREC-i-1])/pow(4294967296.0, i);
    }
    return f;
    //return (b.p ? 1 : -1)*(b.d[PREC-1] + (i == PREC-1 ? 0 : float(b.d[PREC-2])/4294967296.0));
}

vec4 mandelbrot_fixed(cbig p) {
    cbig z = cbig(d2b(0.0), d2b(0.0));
    int i;
    float s = 4;
    for (i = 0; i <= ITER && b2d(sqrb(z)) <= 4; i++) {
        z = addc(sqrc(z), p);
        //s = min(s, abs(4-b2f(sqrb(z))));
    }
    if (b2d(sqrb(z)) <= 4) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        //float v = 0.9-((i - log2(log2(b2f(sqrb(z))) / 2)) / ITER);
        //float v = 1-s;
        //return vec4(v, v, v, 1.0);
        return color(dvec2(b2d(z.x), b2d(z.y)), i);
    }
}

vec4 mandelbrot_float(dvec2 p) {
    dvec2 z = dvec2(0.0, 0.0);
    int i;
    float s = 10;
    for (i = 0; i <= ITER && pytcf(z) <= 4; i++) {
        z = sqrcf(z) + p;
        //s = min(s, abs(4-float(pytcf(z))));
    }
    if (pytcf(z) <= 4) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        //float v = 0.9-((i - log2(log2(float(pytcf(z))) / 2)) / ITER);
        //float v = 1-s/3;
        //return vec4(v, v, v, 1.0);
        return color(vec2(z), i);
    }
}

void main() {
    vec2 resolution = vec2(1280.0, 720.0);
    float rat = float(resolution.x/resolution.y);
    float elev = float(frame)*RATE;
    //float elev = 9;
    dvec2 zoom = dvec2(rat*5.0/pow(10, elev), 5.0/pow(10, elev));

    /*dvec2 center = dvec2(-1.7499576837060935036022145060706997072711057972625207793024283782028,0.00000000000000000278793706563379402178294753790944364927085054500163);
    dvec2 scr = dvec2(gl_FragCoord.xy / resolution.xy);
    dvec2 man = dvec2((center.x - zoom.x) + (2*zoom.x*scr.x), (center.y - zoom.y) + (2*zoom.y*scr.y));
    fragColor = mandelbrot_float(man.xy);*/
    
    uint cx[PREC];
    uint cy[PREC];
    cx[PREC-1] = 1;
    cx[PREC-2] = 3221043724;
    cx[PREC-3] = 3872272384;
    cy[PREC-2] = 51;
    cy[PREC-3] = 1839798819;
    cy[PREC-4] = 2471624704;
    //cbig center = cbig(big(cx, false), big(cy, true));
    cbig center = cbig(d2b(-0.77568377), d2b(0.13646737));
    dvec2 scr = dvec2(gl_FragCoord.xy / resolution.xy);
    cbig man = cbig(addx(subx(center.x, d2b(zoom.x)), d2b(2*zoom.x*scr.x)), addx(subx(center.y, d2b(zoom.y)), d2b(2*zoom.y*scr.y)));
    fragColor = mandelbrot_fixed(man);
    //fragColor = vec4(b2f(subx(addx(f2b(zoom.x * gl_FragCoord.x / resolution.x), center.x), center.x)) / zoom.x, b2f(subx(addx(f2b(zoom.y * gl_FragCoord.y / resolution.y), center.y), center.y)) / zoom.y, 1, 1);
}