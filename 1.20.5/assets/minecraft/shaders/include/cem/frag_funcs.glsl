/* CEM-Shader. DartCat25
*  Fragment functional (set right before main function)
*  #moj_import <cem/frag_funcs.glsl>
*/ 

//Able ins and necessary uniforms
in vec4 cem_pos1, cem_pos2, cem_pos3, cem_pos4;
in vec3 cem_uv1, cem_uv2;
in vec3 cem_glPos;
in vec4 cem_lightMapColor;
flat in int cem;
flat in int cem_reverse;
flat in vec4 cem_light;

#define MAX_DEPTH 1000000

#define ADD_SQUARE(p1, p2, p3, uv) { \
color = sSquare(-center, dirTBN, p1 * modelSize, p2 * modelSize, p3 * modelSize, vertexColor, color, minT, uv);\
}

#define ADD_BOX(pos, size, dSide, uSide, nSide, eSide, sSide, wSide) { \
color = sBox(-center + pos * modelSize, dirTBN, size * modelSize, TBN, color, minT, dSide, uSide, nSide, wSide, sSide, eSide);\
}

#define ADD_BOX_ROTATE(pos, size, Rotation, rotPivot, dSide, uSide, nSide, eSide, sSide, wSide) { \
color = sBox(Rotation * (-center + (pos + rotPivot) * modelSize) - rotPivot * modelSize, Rotation * dirTBN, size * modelSize, TBN * inverse(Rotation), color, minT, dSide, uSide, nSide, wSide, sSide, eSide); \
}

#define ADD_QUAD(p1, p2, p3, p4, uv) { \
}

#define ADD_BOX_EXT(pos, size, dSide, uSide, nSide, eSide, sSide, wSide) { \
color = sBoxExt(-center + pos * modelSize, dirTBN, size * modelSize, TBN, color, minT, dSide, uSide, nSide, wSide, sSide, eSide);\
}

vec3 planeIntersect( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;
    vec3  n = cross( v1v0, v2v0 );
    vec3  q = cross( rov0, rd );
    float d = 1.0/dot( rd, n );
    float u = d*dot( -q, v2v0 );
    float v = d*dot(  q, v1v0 );
    float t = d*dot( -n, rov0 );
    return vec3( u, v, t );
}


//Got from https://iquilezles.org/articles/intersectors/
vec3 squareIntersect( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 val = planeIntersect(ro, rd, v0, v1, v2);
    if(val.x <0.0 || val.y <0.0 || val.x > 1.0 || val.y > 1.0 || val.z < 0) 
        val.z = MAX_DEPTH;
    return val;
}

vec3 triIntersect( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 val = planeIntersect(ro, rd, v0, v1, v2);
    if(val.x <0.0 || val.y <0.0 || val.z < 0 || val.x + val.y > 1)
        val.z = MAX_DEPTH;
    return val;
}

vec3 boxIntersect(vec3 ro, vec3 rd, vec3 size, out vec3 outNormal)
{
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * size;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN > tF || tF < 0.0) return vec3(MAX_DEPTH);

    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    
    float t = tN > 0 ? tN : tF;

    vec3 pos = (ro + rd * t) / size;
    vec2 tex = vec2(0);
    if (abs(outNormal.x) > 0.9)
        tex = pos.zy;
    else if (abs(outNormal.y) > 0.9)
        tex = pos.xz;
    else if (abs(outNormal.z) > 0.9)
        tex = pos.xy;

    return vec3(clamp(tex / 2 + 0.5, vec2(0), vec2(1)), t);
}

vec3 boxIntersectInv(vec3 ro, vec3 rd, vec3 size, out vec3 outNormal)
{
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * size;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN > tF || tF < 0.0) return vec3(MAX_DEPTH);

    outNormal = sign(rd)*step(t2.xyz,t2.yzx)*step(t2.xyz,t2.zxy);

    vec3 pos = (ro + rd * tF) / size;
    vec2 tex = vec2(0);
    if (abs(outNormal.x) > 0.9)
        tex = pos.zy;
    else if (abs(outNormal.y) > 0.9)
        tex = pos.xz;
    else if (abs(outNormal.z) > 0.9)
        tex = pos.xy;

    return vec3(clamp(tex / 2 + 0.5, vec2(0), vec2(1)), tF);
}

void writeDepth(vec3 Pos)
{
    if (ProjMat[3][0] == -1)
    {
        vec4 ProjPos = ProjMat * vec4(Pos, 1);
        gl_FragDepth = ProjPos.z / ProjPos.w * 0.5 + 0.5;
 
    }
    else
    {
        vec4 ProjPos = ProjMat * ModelViewMat * vec4(Pos, 1);
        gl_FragDepth = ProjPos.z / ProjPos.w * 0.5 + 0.5;
    }
}

vec4 sSquare(vec3 ro, vec3 rd, vec3 p1, vec3 p2, vec3 p3, vec4 tint, vec4 color, inout float T, vec4 uv)
{
    vec3 tris = squareIntersect(ro, rd, p1, p2, p3);

    if (tris.z >= T) return color;

    vec4 col = texelFetch(Sampler0, ivec2(uv.xy + uv.zw * tris.xy), 0) * tint;
    
    if (col.a < 0.1) return color;

    T = tris.z;
    return col;
}

vec4 sTris(vec3 ro, vec3 rd, vec3 p1, vec3 p2, vec3 p3, vec4 color, inout float T, vec4 uv)
{
    vec3 tris = triIntersect(ro, rd, p1, p2, p3);

    if (tris.z >= T) return color;

    vec4 col = texelFetch(Sampler0, ivec2(uv.xy + uv.zw * tris.xy), 0);
    
    if (col.a < 0.1) return color;

    T = tris.z;
    return col;
}

vec4 sQuad(vec3 ro, vec3 rd, float modelSize, vec3 p1, vec3 p2, vec3 p3, vec3 p4, vec4 color, inout float T, vec4 uv)
{
    color = sTris(ro, rd, p1 * modelSize, p2 * modelSize, p3 * modelSize, color, T, uv);
    color = sTris(ro, rd, p4 * modelSize, p3 * modelSize, p2 * modelSize, color, T, vec4(uv.xy + uv.zw, -uv.zw));
    return color;
}

vec4 sBox(vec3 ro, vec3 rd, vec3 size, mat3 TBN, vec4 color, inout float T, vec4 dSide, vec4 uSide, vec4 nSide, vec4 eSide, vec4 sSide, vec4 wSide)
{
    vec2 texSize = textureSize(Sampler0, 0);
    vec3 normal = vec3(0);

    vec3 box = boxIntersect(ro, rd, size, normal);

    if (box.z >= T)
        return color;

    vec4 col = vec4(0);

    if (normal.x > 0.9 && eSide != vec4(0)) //East
    {
        col = texture(Sampler0, (eSide.xy + eSide.zw * box.xy) / texSize);
    }
    else if (normal.x < -0.9 && wSide != vec4(0)) //West
    {
        col = texture(Sampler0, (wSide.xy + wSide.zw * vec2(1 - box.x, box.y)) / texSize);
    }
    else if (normal.z > 0.9 && sSide != vec4(0)) //South
    {
        col = texture(Sampler0, (sSide.xy + sSide.zw * vec2(1 - box.x, box.y)) / texSize);
    }
    else if (normal.z < -0.9 && nSide != vec4(0)) //North
    {
        col = texture(Sampler0, (nSide.xy + nSide.zw * box.xy) / texSize);
    }
    else if (normal.y < -0.9 && uSide != vec4(0)) //Up
    {
        col = texture(Sampler0, (uSide.xy + uSide.zw * box.xy) / texSize);
    }
    else if (normal.y > 0.9 && dSide != vec4(0)) //Down
    {
        col = texture(Sampler0, (dSide.xy + dSide.zw * box.xy) / texSize);
    }

    col = minecraft_mix_light(Light0_Direction, Light1_Direction, normalize(TBN * normal), col);

    if (col.a < 0.1) return color;

    T = box.z;

    return col;
}

vec4 sBoxExt(vec3 ro, vec3 rd, vec3 size, mat3 TBN, vec4 color, inout float T, vec4 dSide, vec4 uSide, vec4 nSide, vec4 eSide, vec4 sSide, vec4 wSide)
{
    vec2 texSize = textureSize(Sampler0, 0);
    vec3 normal = vec3(0);

    vec3 box = boxIntersect(ro, rd, size, normal);

    if (box.z >= T)
        return color;

    vec4 col = vec4(0);

    if (normal.x > 0.9 && eSide != vec4(0)) //East
    {
        col = texture(Sampler0, (eSide.xy + eSide.zw * box.xy) / texSize);
    }
    else if (normal.x < -0.9 && wSide != vec4(0)) //West
    {
        col = texture(Sampler0, (wSide.xy + wSide.zw * vec2(1 - box.x, box.y)) / texSize);
    }
    else if (normal.z > 0.9 && sSide != vec4(0)) //South
    {
        col = texture(Sampler0, (sSide.xy + sSide.zw * vec2(1 - box.x, box.y)) / texSize);
    }
    else if (normal.z < -0.9 && nSide != vec4(0)) //North
    {
        col = texture(Sampler0, (nSide.xy + nSide.zw * box.xy) / texSize);
    }
    else if (normal.y < -0.9 && uSide != vec4(0)) //Up
    {
        col = texture(Sampler0, (uSide.xy + uSide.zw * box.xy) / texSize);
    }
    else if (normal.y > 0.9 && dSide != vec4(0)) //Down
    {
        col = texture(Sampler0, (dSide.xy + dSide.zw * box.xy) / texSize);
    }

    if (col.a < 0.1)
    {
        box = boxIntersectInv(ro, rd, size, normal);


        if (normal.x > 0.9 && eSide != vec4(0)) //East
        {
            col = texture(Sampler0, (eSide.xy + eSide.zw * box.xy) / texSize);
        }
        else if (normal.x < -0.9 && wSide != vec4(0)) //West
        {
            col = texture(Sampler0, (wSide.xy + wSide.zw * vec2(1 - box.x, box.y)) / texSize);
        }
        else if (normal.z > 0.9 && sSide != vec4(0)) //South
        {
            col = texture(Sampler0, (sSide.xy + sSide.zw * vec2(1 - box.x, box.y)) / texSize);
        }
        else if (normal.z < -0.9 && nSide != vec4(0)) //North
        {
            col = texture(Sampler0, (nSide.xy + nSide.zw * box.xy) / texSize);
        }
        else if (normal.y < -0.9 && uSide != vec4(0)) //Up
        {
            col = texture(Sampler0, (uSide.xy + uSide.zw * box.xy) / texSize);
        }
        else if (normal.y > 0.9 && dSide != vec4(0)) //Down
        {
            col = texture(Sampler0, (dSide.xy + dSide.zw * box.xy) / texSize);
        }
    }


    col = minecraft_mix_light(Light0_Direction, Light1_Direction, normalize(TBN * normal), col);

    if (col.a < 0.1) return color;

    T = box.z;

    return col;
}
