## fekit modules Usage

### 使用module.exports导出构造函数

Calculation.js

    // 将构造函数 Calculation 通过 module.exports 导出
    function Calculation() {
    }

    Calculation.prototype.add = function(x, y) {
        return x + y;
    };

    module.exports = Calculation;


### 使用exports导出方法

math.js

    exports.add = function() {
        var sum = 0, i = 0, args = arguments, l = args.length;
        while (i < l) {
            sum += args[i++];
        }
        return sum;
    };

increment.js

    var add = require('math').add;

    exports.increment = function(val) {
        return add(val, 1);
    };


### 无任何导出，功能是执行函数或者向全局对象添加方法

add.js

    // 向 avalon 添加 add 方法
    function add(){
        var sum = 0, i = 0, args = arguments, l = args.length;
        while (i < l) {
            sum += args[i++];
        }
        return sum;
    }

    avalon.add = add;


### 作为入口，引入需要的包

    // 引入 avalon json2.js 及 jquery
    require('avalon');
    require('json2');
    require('jquery');

