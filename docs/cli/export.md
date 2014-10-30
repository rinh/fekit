export
============

###usage

    fekit export  导出文件配置到 fekit.config 'export' 列表中 
    
    
###description

只可以导出 `src`目录内的文件，要导出的文件头需要加  `/* [export] */` 或 `/* [export no_version] */`
`fekit.config` 文件中的`export`会生成 
     
     {
       "path": "a.css",
       "no_version": false/true
     }
     
多次导出会覆盖原先的结果

目前只支持`.css`与`.js`后缀