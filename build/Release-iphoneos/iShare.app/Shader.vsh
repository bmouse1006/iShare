//
//  Shader.vsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;
uniform float translate;

varying mediump vec4 colorVarying;
//varying mediump vec2 coordinate;

void main()
{
	gl_Position = position;
    colorVarying = color;
}
