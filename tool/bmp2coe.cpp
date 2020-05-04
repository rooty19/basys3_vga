#include <iostream>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <string>
#include <iterator>
#include <iomanip>
#include <cstring>
#include <cmath>
#include <vector>
#include <bitset> 
using namespace std;
string VER = "0.0.2";
bool debug = false;
int outfile;
string fiex;


unsigned int databyte;
void mam(){
    cout << "Man for bmp2coe: " << endl;
    cout << "Usage: $ bmp2coe -[v/q/r] [file.bmp] [Bit per Color]" << endl;
    cout << "Convert BMP to Memory init File" << endl;
    cout << "Bitmap File support: 1 and 24bit" << endl;
    cout << endl;
    cout << "Function::" << endl;;
    cout << "1 bit Bitmap ... Convert A two-dimensional array(X-Y)" << endl;
    cout << "24bit Bitmap ... Convert A two-dimensional array(Color-Address)" << endl;
    cout << endl;
    cout << "Options::" << endl;
    cout << "\t-v\toutput file for vivado   (.coe)" << endl;
    cout << "\t-q\toutput file for quartus  (.mif)" << endl;
    cout << "\t-r\toutput file for readmem  (.txt)" << endl;
    cout << "\tBit per Color [1-8], Default: 4 bit(4096 Colors)" << endl;
    cout << endl;
    cout << "bmp2coe (Ver:" << VER << ", 2020, rootY)" << endl;
}

uint64_t headrec(string fstreamin, unsigned int startbyte, unsigned int endbyte){
    int bytes = endbyte - startbyte + 1;
    uint8_t formatC[bytes] = {0};
    for(int i=0;i<bytes;i++)formatC[i] = static_cast<uint8_t>(fstreamin[i+startbyte]);
    uint64_t res = 0;
    for(int i=0;i<bytes;i++){
        res = res + (formatC[i]<<(8*i));
    }
    return res;
}

uint8_t rcolorp(string fstream, unsigned int startbyte){
    uint8_t formatC = static_cast<uint8_t>(fstream[startbyte]);
    return formatC;
}

void bitbcut(string fstream, vector<vector<uint8_t>> &pallet ,unsigned int startbyte, unsigned int bpl, unsigned int offset, string Nfilename, unsigned int index){ 
    unsigned charbit = bpl + offset;
    unsigned charbyte = charbit/8;
    uint8_t linebyte[charbyte] = {0};
    ofstream oout(Nfilename+fiex, ios::app);
    //string outl;
    for(int i=0;i<charbyte;i++)linebyte[i] = static_cast<uint8_t>(fstream[i+startbyte]);
    if(debug)cout << hex << startbyte << " : ";//<< hex << +linebyte << endl;
    if(outfile==1)oout << index << "\t:\t"; // Quartus
    bool breakf = false;
    for(unsigned i=0; i<charbyte; i++){
        if(breakf) break;
        for(unsigned j=0;j<8;j++){
            if(i*8+j == bpl){
                breakf=true;
                if(debug)cout << "," << dec << i*8+j-1;
                break;
            }
            uint8_t gl = (linebyte[i] & 0b10000000)>>7;
            linebyte[i] = linebyte[i] << 1;
            for(int k=0;k<3;k++){
                uint8_t rc = pallet[k][gl];
                if(debug)cout << hex << +rc;
            }
            uint outpam = (pallet[0][gl] == 0x00) ? 1:0;
            oout << outpam;
            //cout << hex << +pallet[0][gl];
            //cout << endl;
            if(debug)cout << ", ";
        }
    }
    //cout << endl;
    if(outfile==0){
        if(startbyte!=databyte)oout << endl;
        else oout << ";" << endl;
    }else if(outfile == 1){
        if(startbyte!=databyte)oout << ";" << endl;
        else oout << ";\nEND;" << endl;
    }else oout << endl;
    if(debug) cout << endl;
    oout.close();
}

void bit24cut(string fstream, unsigned long startbyte, unsigned int bpl, string Nfilename, unsigned int index, unsigned bpc){
    unsigned int Bpl = bpl/8;
    uint8_t linebyte[Bpl] = {0};
    for(int i=0;i<Bpl;i++)linebyte[i] = static_cast<uint8_t>(fstream[i+startbyte]);
    ofstream oout(Nfilename+fiex, ios::app);
    for(int i=0;i<Bpl/3;i++){
        if(outfile==1) oout << index*(Bpl/3)+i << " : "; 
        for(int j=0;j<3;j++){
            uint8_t tempa = linebyte[3*i+j]*(pow(2,bpc)-1)/255;
            //uint8_t tempa = linebyte[3*i+j]*15/255;
            //oout << setw(2) << setfill('0') << hex << +linebyte[3*i+j];
            oout << setw(1) << setfill('0') << hex << +tempa;
        }
        if(outfile==1) oout << ";";
        oout << endl;
    }
    oout.close();
}

int main(int argc, char *argv[]){
    bool exf = false;
    unsigned bpc = 4;
    if(argc<3 || 4<argc){
        mam();
        return 0;
    }else if(!strcmp(argv[1], "-h")){
        mam();
        return 0;
    }else if(!strcmp(argv[1], "-v")){
        outfile = 0;
        fiex = ".coe";
    }else if(!strcmp(argv[1], "-q")){
        outfile = 1;
        fiex = ".mif";
    }else if(!strcmp(argv[1], "-r")){
        outfile = 2;
        fiex = ".txt";
    }else{
        mam();
        return 0;
    }

    ifstream ifs(argv[2]);
    if(argv[3]!=0) bpc = atoi(argv[3]);
    for(int i=0;i<argc;i++)cout << argv[i] << ", ";
    cout << "\nBit/Color : " << bpc << endl ;
    if(ifs.fail()){
        cout << "failed open file" << endl;
        return -1;
    }
    string Nfilename = string(argv[2]);
    string str((std::istreambuf_iterator<char>(ifs)), istreambuf_iterator<char>());

    char formatC[2] = {0};
    str.copy(formatC,2);
    if((formatC[0]!=0x42)|(formatC[1]!=0x4d)){
        cout << "File is not BMP" << endl;
        return -1;
    }
    cout << Nfilename.erase(Nfilename.find(".bmp")) << "_new.bmp, " <<  hex << +formatC[0] << +formatC[1] << endl;
    uint64_t filesize = headrec(str,0x02, 0x05);
    cout << dec << "filesize : " << filesize << hex << "(" << filesize <<  ") byte" << endl;
    databyte = headrec(str,0x0a, 0x0d);
    cout << hex << "start : 0x" << headrec(str,0x0a, 0x0d) << endl; // start point
    cout << hex << "Header size : 0x" << headrec(str,0x0e, 0x11) << endl; // header size
    unsigned int palpo = 0x0d + headrec(str,0x0e, 0x11) + 0x01;
    int bcwidth = headrec(str,0x12, 0x15); // bcwidth
    int bcheight = headrec(str,0x16, 0x19);// bcheight
    cout << "width/height : " << dec << bcwidth <<"/" << bcheight << endl; 
    //cout << hex << headrec(str, 0x2e, 0x31) << endl;

    if(headrec(str,0x1e, 0x21)!=0){ // bicompression
        cout << "BMP file is compressed, avoiding..." << endl;
        cout << "(Run length compression is not supported)" << endl;
        return -1;
    }
    
    int bcBitCount = headrec(str,0x1c, 0x1d);
    cout << "bcBitCount : " << dec << bcBitCount << endl;
    int offset = ((bcBitCount*bcwidth)%32==0) ? 0 : 32-((bcBitCount*bcwidth)%32);
    cout << "bits per line : " << dec << bcBitCount*bcwidth << "bits" << endl;
    cout << "offset : " << dec << offset << " bits" << endl;
    cout << "byte per line : " << "0x" << hex << ((bcBitCount*bcwidth) + offset)/8 << endl;
    
    int mode =0;
    switch(bcBitCount){
        case(1): 
            mode = 1;
            break; 
        case(24):
            mode = 24;
            break; 
        default:
            cout << "bcBitCount is invalid" << endl;
            return -1;
    }
    
    vector<vector<uint8_t>> pallet(4, vector<uint8_t>(pow(2,bcBitCount), 0)); 
    if(mode == 1){
        for (int i=0;i<pow(2,bcBitCount);i++){
            cout << hex << palpo+(i*4) << " : ";
            for(int j=0;j<4;j++){
                uint8_t rc = rcolorp(str, palpo+(i*4)+j);
                pallet[j][i] = rc;
                cout << +pallet[j][i] << ", " ;
            }
            cout << endl;
        }
    }
        cout << dec << (bcBitCount*bcwidth+offset)/8 << endl;
            ofstream oout(Nfilename+fiex, ios::trunc);
            if(outfile == 0){
                if(bcBitCount==1)oout << "memory_initialization_radix=2;" << endl;
                else oout << "memory_initialization_radix=16;" << endl;
                oout << "memory_initialization_vector=" << endl;
                oout.close();
            }else if(outfile == 1){
                oout << "-- Quartus Prime generated Memory Initialization File (.mif)" << endl;
                if(bcBitCount == 1){
                    oout << "WIDTH=" << bcwidth << ";" << endl;
                    oout << "DEPTH=" << bcheight << ";" << endl;
                    oout << "ADDRESS_RADIX=UNS;" << endl;
                    oout << "DATA_RADIX=BIN;\n" << endl;
                    oout << "CONTENT BEGIN" << endl;
                }else{
                    oout << "WIDTH=24;" << endl;
                    oout << "DEPTH=" << bcwidth*bcheight << ";" << endl;
                    oout << "ADDRESS_RADIX=UNS;" << endl;
                    oout << "DATA_RADIX=HEX;\n" << endl;
                    oout << "CONTENT BEGIN" << endl;
                }
                oout.close();
            }else if(outfile == 2){
        }
            for(unsigned int i=0;i<bcheight;i++){
            unsigned long bytepos = filesize - /*headrec(str,0x0a, 0x0d) + */(bcBitCount*bcwidth+offset)*(i+1)/8;
            if(bcBitCount==1)bitbcut(str, pallet, bytepos, (bcBitCount*bcwidth), offset, Nfilename, i);
            else if(bcBitCount==24) bit24cut(str, bytepos, (bcBitCount*bcwidth), Nfilename, i, bpc);
        }
}
// setw(keta) << setfill("0") << 
