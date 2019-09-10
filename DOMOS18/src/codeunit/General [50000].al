codeunit 50000 "General"
{
    // version IMP


    trigger OnRun();
    begin
    end;

    procedure CalcSalesHeaderNetWeight(var SalesHeader: Record "Sales Header") OrderNetWeight: Decimal;
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SETRANGE(SalesLine."Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE(SalesLine."Document No.", SalesHeader."No.");
        if SalesLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += SalesLine."Net Weight" * SalesLine.Quantity;
            until SalesLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure CalcPurchHeaderNetWeight(var PurchaseHeader: Record "Purchase Header") OrderNetWeight: Decimal;
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SETRANGE(PurchaseLine."Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SETRANGE(PurchaseLine."Document No.", PurchaseHeader."No.");
        if PurchaseLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += PurchaseLine."Net Weight" * PurchaseLine.Quantity;
            until PurchaseLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure CalcTransferHeaderNetWeight(var TransferHeader: Record "Transfer Header") OrderNetWeight: Decimal;
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SETRANGE(TransferLine."Document No.", TransferHeader."No.");
        if TransferLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += TransferLine."Net Weight" * TransferLine.Quantity;
            until TransferLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure CalcSalesShipmentHeaderNetWeight(var SalesShipmentHeader: Record "Sales Shipment Header") OrderNetWeight: Decimal;
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SETRANGE(SalesShipmentLine."Document No.", SalesShipmentHeader."No.");
        if SalesShipmentLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += SalesShipmentLine."Net Weight" * SalesShipmentLine.Quantity;
            until SalesShipmentLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure CalcTransferShipmentHeaderNetWeight(var TransferShipmentHeader: Record "Transfer Shipment Header") OrderNetWeight: Decimal;
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SETRANGE(TransferShipmentLine."Document No.", TransferShipmentHeader."No.");
        if TransferShipmentLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += TransferShipmentLine."Net Weight" * TransferShipmentLine.Quantity;
            until TransferShipmentLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure CalcReturnShipmentHeaderNetWeight(var ReturnShipmentHeader: Record "Return Shipment Header") OrderNetWeight: Decimal;
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SETRANGE(ReturnShipmentLine."Document No.", ReturnShipmentHeader."No.");
        if ReturnShipmentLine.FINDSET(false, false) then
            repeat
            OrderNetWeight += ReturnShipmentLine."Net Weight" * ReturnShipmentLine.Quantity;
            until ReturnShipmentLine.NEXT = 0;
        exit(OrderNetWeight);
    end;

    procedure LookupPostedSalesInvoice(DocNo: Code[20]);
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.GET(DocNo);
        PAGE.RUNMODAL(PAGE::"Posted Sales Invoice", SalesInvoiceHeader);
    end;

    procedure GetMoneyToWords(Amount: Decimal) OutString: Text[200];
    var
        PrefixPart: Text[50];
        CentsPart: Text[50];
        CurrencyPart: Text[50];
        SmallPart: Text[50];
        ThousandsPart: Text[50];
        MillionsPart: Text[50];
        BillionsPart: Text[50];
        Cents: Integer;
        Small: Integer;
        Thousands: Integer;
        Millions: Integer;
        Billions: Integer;
        SmallH: Integer;
        ThousandsH: Integer;
        MillionsH: Integer;
        BillionsH: Integer;
        SmallN: Integer;
        ThousandsN: Integer;
        MillionsN: Integer;
        BillionsN: Integer;
        TN: array[100] of Text[50];
        TF: array[100] of Text[50];
        HN: array[10] of Text[50];
        HF: array[10] of Text[50];
    begin
        //Developed by cgeo@izor.com

        PrefixPart := '';
        CentsPart := '';
        CurrencyPart := '';
        SmallPart := '';
        ThousandsPart := '';
        MillionsPart := '';
        BillionsPart := '';

        HN[10] := '';
        HN[1] := 'ΕΚΑΤΟΝ';
        HN[2] := 'ΔΙΑΚΟΣΙΑ';
        HN[3] := 'ΤΡΙΑΚΟΣΙΑ';
        HN[4] := 'ΤΕΤΡΑΚΟΣΙΑ';
        HN[5] := 'ΠΕΝΤΑΚΟΣΙΑ';
        HN[6] := 'ΕΞΑΚΟΣΙΑ';
        HN[7] := 'ΕΠΤΑΚΟΣΙΑ';
        HN[8] := 'ΟΧΤΑΚΟΣΙΑ';
        HN[9] := 'ΕΝΝΙΑΚΟΣΙΑ';

        HF[10] := '';
        HF[1] := 'ΕΚΑΤΟΝ';
        HF[2] := 'ΔΙΑΚΟΣΙΕΣ';
        HF[3] := 'ΤΡΙΑΚΟΣΙΕΣ';
        HF[4] := 'ΤΕΤΡΑΚΟΣΙΕΣ';
        HF[5] := 'ΠΕΝΤΑΚΟΣΙΕΣ';
        HF[6] := 'ΕΞΑΚΟΣΙΕΣ';
        HF[7] := 'ΕΠΤΑΚΟΣΙΕΣ';
        HF[8] := 'ΟΧΤΑΚΟΣΙΕΣ';
        HF[9] := 'ΕΝΝΙΑΚΟΣΙΕΣ';

        TN[100] := '';
        TN[1] := 'ΕΝΑ';
        TN[2] := 'ΔΥΟ';
        TN[3] := 'ΤΡΙΑ';
        TN[4] := 'ΤΕΣΣΕΡΑ';
        TN[5] := 'ΠΕΝΤΕ';
        TN[6] := 'ΕΞΙ';
        TN[7] := 'ΕΠΤΑ';
        TN[8] := 'ΟΧΤΩ';
        TN[9] := 'ΕΝΝΕΑ';
        TN[10] := 'ΔΕΚΑ';
        TN[11] := 'ΕΝΤΕΚΑ';
        TN[12] := 'ΔΩΔΕΚΑ';
        TN[13] := 'ΔΕΚΑΤΡΙΑ';
        TN[14] := 'ΔΕΚΑΤΕΣΣΕΡΑ';
        TN[15] := 'ΔΕΚΑΠΕΝΤΕ';
        TN[16] := 'ΔΕΚΑΕΞΙ';
        TN[17] := 'ΔΕΚΑΕΠΤΑ';
        TN[18] := 'ΔΕΚΑΟΧΤΩ';
        TN[19] := 'ΔΕΚΑΕΝΝΕΑ';
        TN[20] := 'ΕΙΚΟΣΙ';
        TN[21] := 'ΕΙΚΟΣΙ ΕΝΑ';
        TN[22] := 'ΕΙΚΟΣΙ ΔΥΟ';
        TN[23] := 'ΕΙΚΟΣΙ ΤΡΙΑ';
        TN[24] := 'ΕΙΚΟΣΙ ΤΕΣΣΕΡΑ';
        TN[25] := 'ΕΙΚΟΣΙ ΠΕΝΤΕ';
        TN[26] := 'ΕΙΚΟΣΙ ΕΞΙ';
        TN[27] := 'ΕΙΚΟΣΙ ΕΠΤΑ';
        TN[28] := 'ΕΙΚΟΣΙ ΟΧΤΩ';
        TN[29] := 'ΕΙΚΟΣΙ ΕΝΝΕΑ';
        TN[30] := 'ΤΡΙΑΝΤΑ';
        TN[31] := 'ΤΡΙΑΝΤΑ ΕΝΑ';
        TN[32] := 'ΤΡΙΑΝΤΑ ΔΥΟ';
        TN[33] := 'ΤΡΙΑΝΤΑ ΤΡΙΑ';
        TN[34] := 'ΤΡΙΑΝΤΑ ΤΕΣΣΕΡΑ';
        TN[35] := 'ΤΡΙΑΝΤΑ ΠΕΝΤΕ';
        TN[36] := 'ΤΡΙΑΝΤΑ ΕΞΙ';
        TN[37] := 'ΤΡΙΑΝΤΑ ΕΠΤΑ';
        TN[38] := 'ΤΡΙΑΝΤΑ ΟΧΤΩ';
        TN[39] := 'ΤΡΙΑΝΤΑ ΕΝΝΕΑ';
        TN[40] := 'ΣΑΡΑΝΤΑ';
        TN[41] := 'ΣΑΡΑΝΤΑ ΕΝΑ';
        TN[42] := 'ΣΑΡΑΝΤΑ ΔΥΟ';
        TN[43] := 'ΣΑΡΑΝΤΑ ΤΡΙΑ';
        TN[44] := 'ΣΑΡΑΝΤΑ ΤΕΣΣΕΡΑ';
        TN[45] := 'ΣΑΡΑΝΤΑ ΠΕΝΤΕ';
        TN[46] := 'ΣΑΡΑΝΤΑ ΕΞΙ';
        TN[47] := 'ΣΑΡΑΝΤΑ ΕΠΤΑ';
        TN[48] := 'ΣΑΡΑΝΤΑ ΟΧΤΩ';
        TN[49] := 'ΣΑΡΑΝΤΑ ΕΝΝΕΑ';
        TN[50] := 'ΠΕΝΗΝΤΑ';
        TN[51] := 'ΠΕΝΗΝΤΑ ΕΝΑ';
        TN[52] := 'ΠΕΝΗΝΤΑ ΔΥΟ';
        TN[53] := 'ΠΕΝΗΝΤΑ ΤΡΙΑ';
        TN[54] := 'ΠΕΝΗΝΤΑ ΤΕΣΣΕΡΑ';
        TN[55] := 'ΠΕΝΗΝΤΑ ΠΕΝΤΕ';
        TN[56] := 'ΠΕΝΗΝΤΑ ΕΞΙ';
        TN[57] := 'ΠΕΝΗΝΤΑ ΕΠΤΑ';
        TN[58] := 'ΠΕΝΗΝΤΑ ΟΧΤΩ';
        TN[59] := 'ΠΕΝΗΝΤΑ ΕΝΝΕΑ';
        TN[60] := 'ΕΞΗΝΤΑ';
        TN[61] := 'ΕΞΗΝΤΑ ΕΝΑ';
        TN[62] := 'ΕΞΗΝΤΑ ΔΥΟ';
        TN[63] := 'ΕΞΗΝΤΑ ΤΡΙΑ';
        TN[64] := 'ΕΞΗΝΤΑ ΤΕΣΣΕΡΑ';
        TN[65] := 'ΕΞΗΝΤΑ ΠΕΝΤΕ';
        TN[66] := 'ΕΞΗΝΤΑ ΕΞΙ';
        TN[67] := 'ΕΞΗΝΤΑ ΕΠΤΑ';
        TN[68] := 'ΕΞΗΝΤΑ ΟΧΤΩ';
        TN[69] := 'ΕΞΗΝΤΑ ΕΝΝΕΑ';
        TN[70] := 'ΕΒΔΟΜΗΝΤΑ';
        TN[71] := 'ΕΒΔΟΜΗΝΤΑ ΕΝΑ';
        TN[72] := 'ΕΒΔΟΜΗΝΤΑ ΔΥΟ';
        TN[73] := 'ΕΒΔΟΜΗΝΤΑ ΤΡΙΑ';
        TN[74] := 'ΕΒΔΟΜΗΝΤΑ ΤΕΣΣΕΡΑ';
        TN[75] := 'ΕΒΔΟΜΗΝΤΑ ΠΕΝΤΕ';
        TN[76] := 'ΕΒΔΟΜΗΝΤΑ ΕΞΙ';
        TN[77] := 'ΕΒΔΟΜΗΝΤΑ ΕΠΤΑ';
        TN[78] := 'ΕΒΔΟΜΗΝΤΑ ΟΧΤΩ';
        TN[79] := 'ΕΒΔΟΜΗΝΤΑ ΕΝΝΕΑ';
        TN[80] := 'ΟΓΔΟΝΤΑ';
        TN[81] := 'ΟΓΔΟΝΤΑ ΕΝΑ';
        TN[82] := 'ΟΓΔΟΝΤΑ ΔΥΟ';
        TN[83] := 'ΟΓΔΟΝΤΑ ΤΡΙΑ';
        TN[84] := 'ΟΓΔΟΝΤΑ ΤΕΣΣΕΡΑ';
        TN[85] := 'ΟΓΔΟΝΤΑ ΠΕΝΤΕ';
        TN[86] := 'ΟΓΔΟΝΤΑ ΕΞΙ';
        TN[87] := 'ΟΓΔΟΝΤΑ ΕΠΤΑ';
        TN[88] := 'ΟΓΔΟΝΤΑ ΟΧΤΩ';
        TN[89] := 'ΟΓΔΟΝΤΑ ΕΝΝΕΑ';
        TN[90] := 'ΕΝΝΕΝΗΝΤΑ';
        TN[91] := 'ΕΝΕΝΝΗΝΤΑ ΕΝΑ';
        TN[92] := 'ΕΝΕΝΝΗΝΤΑ ΔΥΟ';
        TN[93] := 'ΕΝΕΝΝΗΝΤΑ ΤΡΙΑ';
        TN[94] := 'ΕΝΕΝΝΗΝΤΑ ΤΕΣΣΕΡΑ';
        TN[95] := 'ΕΝΕΝΝΗΝΤΑ ΠΕΝΤΕ';
        TN[96] := 'ΕΝΕΝΝΗΝΤΑ ΕΞΙ';
        TN[97] := 'ΕΝΕΝΝΗΝΤΑ ΕΠΤΑ';
        TN[98] := 'ΕΝΕΝΝΗΝΤΑ ΟΧΤΩ';
        TN[99] := 'ΕΝΕΝΝΗΝΤΑ ΕΝΝΕΑ';

        TF[100] := '';
        TF[1] := 'ΜΙΑ';
        TF[2] := 'ΔΥΟ';
        TF[3] := 'ΤΡΕΙΣ';
        TF[4] := 'ΤΕΣΣΕΡΙΣ';
        TF[5] := 'ΠΕΝΤΕ';
        TF[6] := 'ΕΞΙ';
        TF[7] := 'ΕΠΤΑ';
        TF[8] := 'ΟΧΤΩ';
        TF[9] := 'ΕΝΝΕΑ';
        TF[10] := 'ΔΕΚΑ';
        TF[11] := 'ΕΝΤΕΚΑ';
        TF[12] := 'ΔΩΔΕΚΑ';
        TF[13] := 'ΔΕΚΑΤΡΕΙΣ';
        TF[14] := 'ΔΕΚΑΤΕΣΣΕΡΙΣ';
        TF[15] := 'ΔΕΚΑΠΕΝΤΕ';
        TF[16] := 'ΔΕΚΑΕΞΙ';
        TF[17] := 'ΔΕΚΑΕΠΤΑ';
        TF[18] := 'ΔΕΚΑΟΧΤΩ';
        TF[19] := 'ΔΕΚΑΕΝΝΕΑ';
        TF[20] := 'ΕΙΚΟΣΙ';
        TF[21] := 'ΕΙΚΟΣΙ ΜΙΑ';
        TF[22] := 'ΕΙΚΟΣΙ ΔΥΟ';
        TF[23] := 'ΕΙΚΟΣΙ ΤΡΕΙΣ';
        TF[24] := 'ΕΙΚΟΣΙ ΤΕΣΣΕΡΙΣ';
        TF[25] := 'ΕΙΚΟΣΙ ΠΕΝΤΕ';
        TF[26] := 'ΕΙΚΟΣΙ ΕΞΙ';
        TF[27] := 'ΕΙΚΟΣΙ ΕΠΤΑ';
        TF[28] := 'ΕΙΚΟΣΙ ΟΧΤΩ';
        TF[29] := 'ΕΙΚΟΣΙ ΕΝΝΕΑ';
        TF[30] := 'ΤΡΙΑΝΤΑ';
        TF[31] := 'ΤΡΙΑΝΤΑ ΜΙΑ';
        TF[32] := 'ΤΡΙΑΝΤΑ ΔΥΟ';
        TF[33] := 'ΤΡΙΑΝΤΑ ΤΡΕΙΣ';
        TF[34] := 'ΤΡΙΑΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[35] := 'ΤΡΙΑΝΤΑ ΠΕΝΤΕ';
        TF[36] := 'ΤΡΙΑΝΤΑ ΕΞΙ';
        TF[37] := 'ΤΡΙΑΝΤΑ ΕΠΤΑ';
        TF[38] := 'ΤΡΙΑΝΤΑ ΟΧΤΩ';
        TF[39] := 'ΤΡΙΑΝΤΑ ΕΝΝΕΑ';
        TF[40] := 'ΣΑΡΑΝΤΑ';
        TF[41] := 'ΣΑΡΑΝΤΑ ΜΙΑ';
        TF[42] := 'ΣΑΡΑΝΤΑ ΔΥΟ';
        TF[43] := 'ΣΑΡΑΝΤΑ ΤΡΕΙΣ';
        TF[44] := 'ΣΑΡΑΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[45] := 'ΣΑΡΑΝΤΑ ΠΕΝΤΕ';
        TF[46] := 'ΣΑΡΑΝΤΑ ΕΞΙ';
        TF[47] := 'ΣΑΡΑΝΤΑ ΕΠΤΑ';
        TF[48] := 'ΣΑΡΑΝΤΑ ΟΧΤΩ';
        TF[49] := 'ΣΑΡΑΝΤΑ ΕΝΝΕΑ';
        TF[50] := 'ΠΕΝΗΝΤΑ';
        TF[51] := 'ΠΕΝΗΝΤΑ ΜΙΑ';
        TF[52] := 'ΠΕΝΗΝΤΑ ΔΥΟ';
        TF[53] := 'ΠΕΝΗΝΤΑ ΤΡΕΙΣ';
        TF[54] := 'ΠΕΝΗΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[55] := 'ΠΕΝΗΝΤΑ ΠΕΝΤΕ';
        TF[56] := 'ΠΕΝΗΝΤΑ ΕΞΙ';
        TF[57] := 'ΠΕΝΗΝΤΑ ΕΠΤΑ';
        TF[58] := 'ΠΕΝΗΝΤΑ ΟΧΤΩ';
        TF[59] := 'ΠΕΝΗΝΤΑ ΕΝΝΕΑ';
        TF[60] := 'ΕΞΗΝΤΑ';
        TF[61] := 'ΕΞΗΝΤΑ ΜΙΑ';
        TF[62] := 'ΕΞΗΝΤΑ ΔΥΟ';
        TF[63] := 'ΕΞΗΝΤΑ ΤΡΕΙΣ';
        TF[64] := 'ΕΞΗΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[65] := 'ΕΞΗΝΤΑ ΠΕΝΤΕ';
        TF[66] := 'ΕΞΗΝΤΑ ΕΞΙ';
        TF[67] := 'ΕΞΗΝΤΑ ΕΠΤΑ';
        TF[68] := 'ΕΞΗΝΤΑ ΟΧΤΩ';
        TF[69] := 'ΕΞΗΝΤΑ ΕΝΝΕΑ';
        TF[70] := 'ΕΒΔΟΜΗΝΤΑ';
        TF[71] := 'ΕΒΔΟΜΗΝΤΑ ΜΙΑ';
        TF[72] := 'ΕΒΔΟΜΗΝΤΑ ΔΥΟ';
        TF[73] := 'ΕΒΔΟΜΗΝΤΑ ΤΡΕΙΣ';
        TF[74] := 'ΕΒΔΟΜΗΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[75] := 'ΕΒΔΟΜΗΝΤΑ ΠΕΝΤΕ';
        TF[76] := 'ΕΒΔΟΜΗΝΤΑ ΕΞΙ';
        TF[77] := 'ΕΒΔΟΜΗΝΤΑ ΕΠΤΑ';
        TF[78] := 'ΕΒΔΟΜΗΝΤΑ ΟΧΤΩ';
        TF[79] := 'ΕΒΔΟΜΗΝΤΑ ΕΝΝΕΑ';
        TF[80] := 'ΟΓΔΟΝΤΑ';
        TF[81] := 'ΟΓΔΟΝΤΑ ΜΙΑ';
        TF[82] := 'ΟΓΔΟΝΤΑ ΔΥΟ';
        TF[83] := 'ΟΓΔΟΝΤΑ ΤΡΕΙΣ';
        TF[84] := 'ΟΓΔΟΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[85] := 'ΟΓΔΟΝΤΑ ΠΕΝΤΕ';
        TF[86] := 'ΟΓΔΟΝΤΑ ΕΞΙ';
        TF[87] := 'ΟΓΔΟΝΤΑ ΕΠΤΑ';
        TF[88] := 'ΟΓΔΟΝΤΑ ΟΧΤΩ';
        TF[89] := 'ΟΓΔΟΝΤΑ ΕΝΝΕΑ';
        TF[90] := 'ΕΝΝΕΝΗΝΤΑ';
        TF[91] := 'ΕΝΕΝΝΗΝΤΑ ΜΙΑ';
        TF[92] := 'ΕΝΕΝΝΗΝΤΑ ΔΥΟ';
        TF[93] := 'ΕΝΕΝΝΗΝΤΑ ΤΡΕΙΣ';
        TF[94] := 'ΕΝΕΝΝΗΝΤΑ ΤΕΣΣΕΡΙΣ';
        TF[95] := 'ΕΝΕΝΝΗΝΤΑ ΠΕΝΤΕ';
        TF[96] := 'ΕΝΕΝΝΗΝΤΑ ΕΞΙ';
        TF[97] := 'ΕΝΕΝΝΗΝΤΑ ΕΠΤΑ';
        TF[98] := 'ΕΝΕΝΝΗΝΤΑ ΟΧΤΩ';
        TF[99] := 'ΕΝΕΝΝΗΝΤΑ ΕΝΝΕΑ';

        if Amount = 0 then begin
            OutString := 'ΜΗΔΕΝ ΕΥΡΩ';
            exit;
        end;

        if Amount < 0 then begin
            Amount := -Amount;
            PrefixPart := 'ΜΕΙΟΝ ';
        end;

        Cents := ROUND(100 * (Amount - ROUND(Amount, 1, '<')), 1, '<');
        if Cents > 0 then begin
            if Amount >= 1 then begin
                if Cents = 1 then
                    CentsPart := 'ΚΑΙ ΕΝΑ ΛΕΠΤΟ'
                else begin
                    if Cents = 0 then
                        Cents := 100;
                    CentsPart := 'ΚΑΙ ' + TN[Cents] + ' ΛΕΠΤΑ';
                end;
            end
            else begin
                if Cents = 1 then
                    CentsPart := 'ΕΝΑ ΛΕΠΤΟ'
                else begin
                    if Cents = 0 then
                        Cents := 100;
                    CentsPart := TN[Cents] + ' ΛΕΠΤΑ';
                end;
            end;
        end;

        if Amount >= 1 then
            CurrencyPart := ' ΕΥΡΩ';

        Billions := ROUND((Amount / POWER(10, 9)), 1, '<');
        Millions := ROUND((ROUND((Amount - Billions * POWER(10, 9)), 1, '<') / POWER(10, 6)), 1, '<');
        Thousands := ROUND((ROUND((Amount - Billions * POWER(10, 9) - Millions * POWER(10, 6)), 1, '<') / POWER(10, 3)), 1, '<');
        Small := ROUND((Amount - Billions * POWER(10, 9) - Millions * POWER(10, 6) - Thousands * POWER(10, 3)), 1, '<');

        BillionsH := ROUND((Billions / 100), 1, '<');
        MillionsH := ROUND((Millions / 100), 1, '<');
        ThousandsH := ROUND((Thousands / 100), 1, '<');
        SmallH := ROUND((Small / 100), 1, '<');

        SmallN := Small - SmallH * 100;
        ThousandsN := Thousands - ThousandsH * 100;
        MillionsN := Millions - MillionsH * 100;
        BillionsN := Billions - BillionsH * 100;

        if Small = 100 then
            SmallPart := 'ΕΚΑΤΟ'
        else begin
            if SmallH = 0 then
                SmallH := 10;
            if SmallN = 0 then
                SmallN := 100;
            SmallPart := HN[SmallH] + ' ' + TN[SmallN];
        end;

        if Thousands = 1 then
            ThousandsPart := ' ΧΙΛΙΑ'
        else begin
            if Thousands = 100 then
                ThousandsPart := 'ΕΚΑΤΟ ΧΙΛΙΑΔΕΣ'
            else begin
                if Thousands > 0 then begin
                    if ThousandsH = 0 then
                        ThousandsH := 10;
                    if ThousandsN = 0 then
                        ThousandsN := 100;
                    ThousandsPart := HF[ThousandsH] + ' ' + TF[ThousandsN] + ' ΧΙΛΙΑΔΕΣ';
                end;
            end;
        end;

        if Millions = 1 then
            MillionsPart := 'ΕΝΑ ΕΚΑΤΟΜΜΥΡΙΟ'
        else begin
            if Millions = 100 then
                MillionsPart := 'ΕΚΑΤΟ ΕΚΑΤΟΜΜΥΡΙΑ'
            else begin
                if Millions > 0 then begin
                    if MillionsH = 0 then
                        MillionsH := 10;
                    if MillionsN = 0 then
                        MillionsN := 100;
                    MillionsPart := HN[MillionsH] + ' ' + TN[MillionsN] + ' ΕΚΑΤΟΜΜΥΡΙΑ';
                end;
            end;
        end;

        if Billions = 1 then
            BillionsPart := 'ΕΝΑ ΔΙΣΕΚΑΤΟΜΜΥΡΙΟ'
        else begin
            if Billions = 100 then
                BillionsPart := 'ΕΚΑΤΟ ΔΙΣΕΚΑΤΟΜΜΥΡΙΑ'
            else begin
                if Billions > 0 then begin
                    if BillionsH = 0 then
                        BillionsH := 10;
                    if BillionsN = 0 then
                        BillionsN := 100;
                    BillionsPart := HN[BillionsH] + ' ' + TN[BillionsN] + ' ΔΙΣΕΚΑΤΟΜΜΥΡΙΑ';
                end;
            end;
        end;

        OutString := PrefixPart + BillionsPart + ' ' + MillionsPart + ' ' + ThousandsPart + ' ' +
                       SmallPart + CurrencyPart + ' ' + CentsPart;

        OutString := DELCHR(OutString, '<');
        // Return Trim(Amount.ToString);
    end;
}

