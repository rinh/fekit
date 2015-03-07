install
=====================

### usage

    fekit install  根据 'fekit.config' 内的配置安装
    
    fekit install <name> [-c] 参数为组件名,安装指定组件最新版,并写入'fekit.config' 若加 '-c' 则为强制使用配置文件中的版本范围，如果没有配置文件或配置文件中没有配置，就不安装
    
    fekit install <name>@<version> [-c] 安装指定组件 ,并写入'fekit.config' ,若加 '-c' 则为强制使用配置文件中的版本范围，如果没有配置文件或配置文件中没有配置，就不安装
                                                  
    
### description 

   用来安装fekit组件
    
   需要使用 fekit config 指令来指定下载源
    
   若需使用 `-c` ，需要配置 `fekit.config` 中的依赖
    
    
    