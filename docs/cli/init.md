init
================

### usage

    fekit init [name]  可选参数 : name , 若添加 , 则会新建项目文件夹
   
### description
   
   新建一个fekit项目,若存在 `fekit.config` 文件,则无法新建。
   
   新项目包含: `src` 文件夹, `README.md` , `environment.yaml`配置信息, `fekit.config`配置文件
   
   默认配置信息为
    
    local:
        DEBUG: true
    
    dev:
        DEBUG: true
    
    prd:
        DEBUG: false