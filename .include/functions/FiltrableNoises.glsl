#ifndef FILTRABLE_NOISE_GLSL
#define FILTRABLE_NOISE_GLSL

#include globals/Constants.glsl
#include functions/Hash.glsl

vec2 rotate(vec2 uv, vec2 c, float a)
{
    uv -= c;

    uv = vec2(
        uv.x*cos(a) - uv.y*sin(a),
        uv.x*sin(a) + uv.y*cos(a)
    );

    return uv + c;
}

/* ###===== Vulpine's Filtered Spike Noise =====###
*
*   This is a filtrable and fast noise function that emulate random spikes on a flat surface.
*
*   This noise is highly parametrable, with an alpha value that aims to emulate a non-stationnary
*   behaviour.
*
*/
float FilteredSpikeNoise(
    vec2 uv,            /* UV of the sample. From -10⁷ to +10⁷ for the vulpine hash tu be define */
    float res,          /* Resolution / scale of the noise */
    int iterations,     /* Number of iteration. More iteration = more spikes but slower. From 1 to 17.*/
    float alpha,        /* The wanted average intensity */
    float exageration,  /* Exageration of the spikes sharpiness */
    float seed,          /* Seed of the effect */
    float displacement  /* Displacement added to the random overlaping grid, usefull to animate this noise*/
    )
{
    vec2[17] gridOff = vec2[17](
        vec2(+.0, +.0),

        vec2(+.5, +.5)*SQR2,
        vec2(-.5, +.5)*SQR2*SQR3,
        vec2(+.5, -.5)*SQR2*SQR3,
        vec2(-.5, -.5)*SQR2*E,

        vec2(+.5, +.0)*PI,
        vec2(-.0, +.5)*PI*SQR2,
        vec2(+.0, -.5)*PI*SQR2,
        vec2(-.5, -.0)*PI*E,
    
        vec2(+.5, +.5)*PHI,
        vec2(-.5, +.5)*PHI*PI,
        vec2(+.5, -.5)*PHI*E,
        vec2(-.5, -.5)*PHI*SQR2,

        vec2(+.5, +.0)*E,
        vec2(-.0, +.5)*E*PHI,
        vec2(+.0, -.5)*E*PI,
        vec2(-.5, -.0)*E*E
    );

    uv /= res;

    float filterD = length(max(dFdx(uv), dFdy(uv)));
    float filterLevel = filterD*2.5;

    float fullResNoise = 0.;
    float filteredNoise = 0.;
    
    /* Average energy of the noise depending on alpha */
    // float avgNoise = alpha*alpha*float(iterations)*0.06;
    alpha = 1. - alpha;


    for(int i = 0; i < iterations; i++)
    {
        float dn = 0.;
        float dw = 0.;

        vec2 iuv = uv + gridOff[i] + displacement*(.5 - vulpineHash2to2(i.rr, seed));

        iuv = rotate(iuv, -2.*gridOff[i],  PI*(.5 - vulpineHash2to1(i.rr, seed))*2.);

        for(int mi = -1; mi <= 1; mi++)
        for(int mj = -1; mj <= 1; mj++)
        {
            vec2 duv = iuv + vec2(mi, mj);
            vec2 cuv = round(duv) + .25*vulpineHash2to2(round(duv), seed);
            float intensity = mix(.35, exageration * smoothstep(-1., 1., alpha), vulpineHash2to1(cuv, seed) + alpha);

            /* Full Res Noise Calculation */
            if(mj == 0 && mi == 0)
                fullResNoise += smoothstep(0., intensity, 1. - 4.*distance(duv, cuv));
            
            /* Cell's approximate average energy */
            float w = clamp(1. - distance(iuv, duv), 1., 0.);
            dw += w;
            float r2 = 1. - min(intensity, 1.);
            dn += w * (PI/48.)*(1. - r2*r2)/intensity;
        }

        filteredNoise += dn / dw;
    }
    /* Mix between LOD 1 and LOD 2 */
    // filteredNoise = mix(filteredNoise, avgNoise, smoothstep(5., 24., filterLevel));

    /* Final mix between full res noise and filtered version */
    return mix(fullResNoise, filteredNoise, smoothstep(0., 1., filterLevel));
}


//=======================================================
//= Filtered Local Random Phase Noise 
//=======================================================
//== Based on the filtering process of Gabor Noise from Lagae et al. 2009
//== http://graphics.cs.kuleuven.be/publications/LLDD09PNSGC/
//== replaced the Kaiser Bessel Window of the original paper by a Gaussian Window
//== https://www.unilim.fr/pages_perso/guillaume.gilet/publications/pdf/ProcTextures.pdf
//== A blog post explaining the details of calculation : https://h4w0.frama.io/pages/posts/2019-09-30-FilteredLRPN.html
//== Author : Arthur Cavalier
//=======================================================

    // User Parameters -----------------------------------------------------------------
    const int   LRPN_COSINES     = 5;
    const float LRPN_RESOLUTION  = 15.0;
    const uint  LRPN_GLOBAL_SEED = 0u;

    // Quick Matrix Maths
    float determinant_2x2(in mat2 m)         {return (m[0][0]*m[1][1] - m[0][1]*m[1][0]);}

    // PRNG ----------------------------------------------------------------------------
    // Pseudo Random Number Generation
    // From Texton Noise Source Code provided by Arthur Leclaire et al. 
    // https://www.idpoisson.fr/galerne/texton_noise/index.html
    // Sourced ::
    /* 
    * From http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
    * Same strategy as in Gabor noise by example
    * Apply hashtable to create cellseed
    * Use a linear congruential generator as fast PRNG
    */

    uint  wang_hash(uint seed)                                          {seed=(seed^61u)^(seed>>16u);seed*=9u;seed=seed^(seed>>4u);seed*=668265261u;seed=seed^(seed>>15u);return(seed);}
    uint  cell_seed(const in ivec2 c, const in uint offset)             {const uint period=1024u;uint s=((uint(c.y)%period)*period+(uint(c.x)%period))*period+offset; if(s==0u){s = 1u;}return(s);}
    uint  myrand(inout uint p)                                          {p^=(p<<13u);p^=(p>>17u);p^=(p<<5u);return p;}
    float myrand_uniform_0_1(inout uint p)                              {return float(myrand(p))/float(4294967295u);}
    float myrand_uniform_m_M(inout uint p, in float mi, in float ma)    {return mi + (myrand_uniform_0_1(p) * (ma - mi));}


    //--------------------------------------------------------------------------------------------------------
    //-- Gaussian Window Function ----------------------------------------------------------------------------
    float gaussian(in vec2 st, in float c, in vec2 mu, in mat2 sig)
    {
        vec2 p = st-mu;
        float body = -0.5*dot(p,inverse(sig)*p);
        return c*exp(body);
    }

    float gaussian_inv_sigma(in vec2 st, in float c, in vec2 mu, in mat2 inv_sig)
    {
        vec2 p = st-mu;
        float body = -0.5*dot(p,inv_sig*p);
        return c*exp(body);
    }

    //--------------------------------------------------------------------------------------------------------
    //-- Filtered Local Random Phase Noise -------------------------------------------------------------------
    float filtered_local_random_phase_noise(
            in vec2  texcoords,
            in float resolution,
            in int   cosines,
            in vec2  range_frequency,
            in vec2  range_orientation
        )
    {
        vec2  scaled_coords = texcoords * resolution;
        vec2  cell_coords   = fract(scaled_coords);
        vec2  cell_index    = floor(scaled_coords);
        
        ivec2 cell_ID;
        uint  prng, seed;
        
        float lrpn   = 0.;
        float weight = 1. / float(cosines);
        float alpha  = 1./1.2;

        mat2  Jacobian = mat2( 0.5*dFdx(scaled_coords), 0.5*dFdy(scaled_coords) );
        mat2  Filter_Sigma = Jacobian*transpose(Jacobian);
        mat2  Filter_InvSigma = inverse(Filter_Sigma);
        float Filter_Lambda = 1.0 / (2.*PI*sqrt(determinant_2x2(Filter_Sigma)));

        mat2 Gabor_Sigma = mat2( 1.0 / (2.*PI*alpha*alpha) );
        mat2 Gabor_InvSigma = mat2( 2.*PI*alpha*alpha );
        mat2 Product_InvSigma = Filter_Sigma+Gabor_Sigma;
        mat2 Product_Sigma = inverse(Product_InvSigma);

        for (int m=-1; m<=+1; m++)
        for (int n=-1; n<=+1; n++)
        {
            cell_ID.x = int(cell_index.x) + m;
            cell_ID.y = int(cell_index.y) + n;
            seed = cell_seed(cell_ID,LRPN_GLOBAL_SEED);
            prng = wang_hash(seed);

            vec2 xy = cell_coords - vec2(m,n) - vec2(0.5);
            
            float sum_of_cosines    = 0.; 
            for(int k=0; k<cosines; k++)
            {
                float fr = myrand_uniform_m_M(prng,range_frequency.x,range_frequency.y) * resolution;   // Scaled Frequency 
                float or = myrand_uniform_m_M(prng,range_orientation.x,range_orientation.y);            // Orientation
                float ph = PI*(myrand_uniform_0_1(prng)*2.-1.);                                       // Phase
                
                vec2 Gabor_Mean = 2.*PI * fr * vec2(cos(or),sin(or));  // Oriented Frequency
                
                // Now we compute the product of the gaussian footprint and the 
                // fourier transform of the gabor kernel in the spectral domain
                
                vec2 Product_Mean = Product_Sigma * Gabor_Sigma * Gabor_Mean; // \mu_3

                float scale_gabor = sqrt(determinant_2x2(Gabor_Sigma)*determinant_2x2(Product_Sigma));
                scale_gabor *= gaussian(vec2(0.),1.,Gabor_Mean,Filter_InvSigma+Gabor_InvSigma); //\lambda_3
                scale_gabor *= gaussian_inv_sigma(xy,1.,vec2(0.),Product_Sigma); // new window
                float filtered_harmonic = dot(xy, Product_Mean) + ph; // new harmonic

                sum_of_cosines   += scale_gabor * cos(filtered_harmonic) ; // the new anisotropic gabor kernel
            }
            lrpn += weight * sum_of_cosines;
        }
        return lrpn;
    }

#endif