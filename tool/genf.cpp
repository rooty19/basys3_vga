#include <iostream>
#include <bitset>
#include <string>
/*
なんか良い感じにOnehot->2進デコーダを生成するスクリプト
*/
const int OHWIDTH = 50; // OneHotの数
const int DEWIDTH = 6; // ln(OneHotの数)
const int OFFSET = -1; // 右側の変数へのオフセット
uint64_t onehot = 0;
std::string outwire = "ohde"; // Wireの名前

int main(){
    int i=0;
    for(int i=0;i<=OHWIDTH;i++){
        std::cout << OHWIDTH << "'b" << std::bitset<OHWIDTH>(onehot) << " : " << outwire << " <= " << DEWIDTH << "'d" << i + OFFSET << ";" << std::endl;
        onehot = (onehot == 0) ? 1 : onehot << 1;
    }
}