module HazardDetect(
    input memtoreg, //INかLWでアサート、データハザードを起こす命令の検知
    input [15:0] I, //命令16bitコード
    input [2:0] Rt, //前の命令の書き込み先
    output reg PCwrite, //PC書き込み許可信号
    output reg IFIDwrite, //IF/ID書き込み許可信号
    output reg stall //ストール信号
);
    wire [1:0] op=I[15:14]; //命令の分類
    wire [2:0] reg1=I[13:11]; //レジスタ指定フィールド
    wire [2:0] reg2=I[10:8]; //レジスタ指定フィールド
    wire [3:0] op3=I[7:4]; //演算種別
    always @(*) begin // デフォルトではストールしない
    PCwrite=1'b1;
    IFIDwrite=1'b1;
    stall=1'b0;
    if(({op,op3}==6'b110000)|| //ADD
            ({op,op3}==6'b110001)|| //SUB
            ({op,op3}==6'b110010)|| //AND
            ({op,op3}==6'b110011)|| //OR
            ({op,op3}==6'b110100)|| //EXOR
            ({op,op3}==6'b110101)|| //CMP
            (op==2'b01) //SW
            ) begin //reg1,reg2両方使う命令
        if(memtoreg) begin
            if(Rt==reg1||Rt==reg2) begin // PCとIF/IDレジスタを保持し、ID/EX段へバブルを挿入する

                PCwrite=1'b0;
                IFIDwrite=1'b0;
                stall=1'b1;
            end
        end
    end
    else if(({op,op3}==6'b110110)|| //MOV
            ({op,op3}==6'b111101) //OUT
            ) begin //reg1のみ使う命令
        if(memtoreg) begin
            if(Rt==reg1) begin
                PCwrite=1'b0;
                IFIDwrite=1'b0;
                stall=1'b1;
            end
        end
    end
    else if(({op,op3}==6'b110111)|| //ADDi(Rd+即値)
            ({op,op3}==6'b111000)|| //shift↓
            ({op,op3}==6'b111001)||
            ({op,op3}==6'b111010)||
            ({op,op3}==6'b111011)||
            (op==2'b00) //LW
            ) begin //reg2のみ使う命令
        if(memtoreg) begin
            if(Rt==reg2) begin //Load-Useハザード検出
                PCwrite=1'b0;
                IFIDwrite=1'b0;
                stall=1'b1;
            end
        end
    end
end
endmodule
