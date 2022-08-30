pragma solidity ^0.8.0;

library ArrayUtils {

    //删除指定索引的数组元素
    function removeAtIndex(uint[] storage array, uint index) public {
        if (index >= array.length) return;

        for (uint i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }

        delete array[array.length-1];
        array.pop();

    }
}
