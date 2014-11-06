min
==============

###usage

    fekit min [-v] [-m] 
    压缩,合并项目文件 ,`-v` 与 `-m`为可选项 ,分别为  在 `/ver` 目录中只生成 version 文件 和在 `/ver` 目录中只生成 mapping 文件         
    把`dev`目录中的文件压缩到`prd`目录中
    
    fekit min -f <fname> [-n] [-c] [-o <path>] 
    指定编译某个文件, 而不是当前目录. 处理后默认将文件放在同名目录下并加后缀 min。
    可选项 `-n` , 不进行压缩处理, 如编译 coffee文件,若使用`-n` 则不会压缩编译后的js文件
    可选项 `-c` , 不分割 css 为多行形式,默认分割, 使用后css合并为一行
    可选项 `-o` ,  指定单个文件编译的输出位置, 默认在相同文件夹下
                
                
###description

   默认压缩引擎
   `js`使用`uglify-js`,
   `css`使用`uglifycss`
   
   支持编译的文件类型
   `coffee, css, js, handlebars, less, mustache, ng, ngc, sass, scss, string`
   
   使用是需要添加文件后缀名, 若重复编译则会覆盖先前的文件
   
   
   
    
   
    
    
    
