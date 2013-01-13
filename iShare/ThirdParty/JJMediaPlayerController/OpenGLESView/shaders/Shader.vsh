//
//  Shader.vsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;
varying vec4 colorVarying;

uniform float translate;

void main()
{
	gl_Position = position;
    colorVarying = color;
}
