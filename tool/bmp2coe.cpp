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
string VER = "0.0.1";
bool debug = false;
int outfile;
string fiex;


unsigned int databyte;
void mam(){
    cout << "Man for bmp2coe: " << endl;
    cout << "Usage: $ bmp2coe -[v/q/r] [file.bmp] -[12/24]" << endl;
    cout << "Convert BMP to Memory init File" << endl;
    cout << "1/4/8 bit Bitmap ... Convert Simplify" << endl;
    cout << "\t-v\toutput file for vivado   (.coe)" << endl;
    cout << "\t-q\toutput file for quartus  (.mif)" << endl;
    cout << "\t-r\toutput file for readmem (.txt)" << endl;
    cout << "bmp2coe (Ver:" << VER << ", 2020)" << endl;
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

void bitqcut(string fstream, vector<vector<uint8_t>> &pallet ,unsigned int startbyte, unsigned int bpl, unsigned int offset, string Nfilename, unsigned int index){ 
    unsigned charbit = bpl + offset;
    unsigned charbyte = charbit/8;
    uint8_t linebyte[charbyte] = {0};
    ofstream oout(Nfilename+fiex, ios::app);
    for(int i=0;i<charbyte;i++)linebyte[i] = static_cast<uint8_t>(fstream[i+startbyte]);
    if(debug)cout << setw(3) << setfill('0') << hex << startbyte << " : " << setfill(' ') << setw(0);//<< hex << +linebyte << endl;
    int i=0;
    uint8_t ac0, ac1;
    uint8_t rc0[3], rc1[3];
    /*
    if(debug){
        for(int a=0;a<charbyte;a++){
            cout << setw(2) << setfill('0') << hex << +static_cast<uint8_t>(linebyte[a]) << ", ";
        }
        cout << setfill(' ') << setw(0) << "\n\t";
    }
    */
    for(i=0;i<bpl/8;i++){
        ac0=(linebyte[i]& 0b11110000)>>4;
        ac1=(linebyte[i]& 0b00001111);
        for(int j=0;j<3;j++){
            rc0[j] = pallet[j][ac0];
            rc1[j] = pallet[j][ac1];    
        }
        if(debug)cout << +ac0 << +ac1;
        if(outfile==1)oout << setw(4) << setfill('0') << dec << index*(bpl/4)+i*2 << " : ";
        for(int j=0;j<3;j++)oout  << hex << setw(2) << setfill('0') << +rc0[j];
        if(outfile==1)oout << ";";
        oout << endl;
        if(outfile==1)oout  << setw(4) << setfill('0') << dec << index*(bpl/4)+i*2+1 << " : ";
        for(int j=0;j<3;j++)oout << hex << setw(2) << setfill('0') << +rc1[j];
        if(outfile==1)oout << ";";
        oout << endl;
    }
    if(bpl%8==4){
        ac0=(linebyte[i]&0b11110000)>>4;
        cout << +ac0 << endl;
        for(int j=0;j<3;j++){
            rc0[j] = pallet[j][ac0];   
        }
        if(outfile==1)oout << setw(4) << setfill('0') << dec << index*(bpl/4)+i*2 << " : ";
        oout <<  setw(2) << setfill('0') << hex << +rc0[0] << +rc0[1] << +rc0[2] << setw(0) << setfill('0');
        if(outfile==1)oout << ";";
        oout << endl;
    }
    //cout << setfill(' ') << setw(0) << dec << l << endl;
    //cout << endl;

    if(outfile==0 && startbyte==databyte)oout << ";" << endl;
    else if(outfile == 1 && startbyte==databyte) oout << "END;" << endl;
    oout.close();
}

void bitocut(string fstream, vector<vector<uint8_t>> &pallet ,unsigned int startbyte, unsigned int bpl, unsigned int offset, string Nfilename, unsigned int index){ 
    unsigned charbit = bpl + offset;
    unsigned charbyte = charbit/8;
    //cout << hex << charbit << ", " << charbyte << endl;
    char linebyte[charbyte] = {0};
    ofstream oout(Nfilename+fiex, ios::app);
    //string outl;
    fstream.copy(linebyte, charbyte, startbyte);
    if(debug)cout << setw(3) << setfill('0') << hex << startbyte << " : " << setfill(' ') << setw(0);//<< hex << +linebyte << endl;
    int i=0;
    uint8_t ac0;
    uint8_t rc0[3];
    for(i=0;i<bpl/8;i++){
        ac0=static_cast<uint8_t>(linebyte[i]);
        for(int j=0;j<3;j++)rc0[j] = pallet[j][ac0];
        if(debug)cout << setw(2) << setfill('0') << hex << +ac0;
        if(outfile==1)oout << setw(4) << setfill('0') << dec << index*(bpl/8)+i << " : ";
        for(int j=0;j<3;j++)oout << setw(2) << setfill('0') << hex << +rc0[j];
        if(outfile==1)oout << ";";
        if(i!=bpl-1) oout << endl;
    }
    if(debug) cout << endl;
    if(outfile==0 && startbyte==databyte)oout << ";" << endl;
    else if(outfile == 1 && startbyte==databyte) oout << "END;" << endl;
    oout.close();
}

void bit24cut(string fstream, unsigned long startbyte, unsigned int bpl, string Nfilename, unsigned int index){
    unsigned int Bpl = bpl/8;
    uint8_t linebyte[Bpl] = {0};
    for(int i=0;i<Bpl;i++)linebyte[i] = static_cast<uint8_t>(fstream[i+startbyte]);
    ofstream oout(Nfilename+fiex, ios::app);
    for(int i=0;i<Bpl/3;i++){
        if(outfile==1) oout << index*(Bpl/3)+i << " : ";
        for(int j=0;j<3;j++)oout << setw(2) << setfill('0') << hex << +linebyte[3*i+j];
        if(outfile==1) oout << ";";
        oout << endl;
    }
    oout.close();
}

int main(int argc, char *argv[]){
    bool exf = false;
    
    cout << argv[1] << endl;
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
            mode = 0;
            break; 
        case(4):
            mode = 4;
            break; 
        case(8):    
            mode = 8;
            break; 
        case(24):
            mode = 24;
            break; 
        default:
            cout << "bcBitCount is invalid" << endl;
            return -1;
    }
    
    vector<vector<uint8_t>> pallet(4, vector<uint8_t>(pow(2,bcBitCount), 0)); 
    if(mode <= 8){
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
            else if(bcBitCount==4) bitqcut(str, pallet, bytepos, (bcBitCount*bcwidth), offset, Nfilename, i);
            else if(bcBitCount==8) bitocut(str, pallet, bytepos, (bcBitCount*bcwidth), offset, Nfilename, i);
            else if(bcBitCount==24) bit24cut(str, bytepos, (bcBitCount*bcwidth), Nfilename, i);
        }
}
// setw(keta) << setfill("0") << 
