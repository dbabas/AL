report 50004 "Cash Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Cash Receipt.rdlc';
    CaptionML = ELL='Απόδειξη Πληρωμής Πελάτη',
                ENU='Customer Payment Receipt';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Cust. Ledger Entry";"Cust. Ledger Entry")
        {
            DataItemTableView = WHERE("Document Type"=FILTER(" "|Payment|Refund));
            RequestFilterFields = "Customer No.","Posting Date","Document No.";
            column(DocNo;"Document No.")
            {
            }
            column(DocDate;"Document Date")
            {
            }
            column(Amount;Amount)
            {
            }
            column(CompInfName;CompanyInfo.Name)
            {
            }
            column(CompInfProf;CompanyInfo.Profession)
            {
            }
            column(CompAddress;CompanyAddress)
            {
            }
            column(CompTaxData;CompanyTaxData)
            {
            }
            column(LblNo;LblNo)
            {
            }
            column(LblDate;LblDate)
            {
            }
            column(PrintTitle;PrintTitle)
            {
            }
            column(PrintTo;PrintTo)
            {
            }
            column(PrintFrom;PrintFrom)
            {
            }
            column(Lbl1;Lbl1)
            {
            }
            column(Lbl2;Lbl2)
            {
            }
            column(Lbl3;Lbl3)
            {
            }
            column(Lbl4;Lbl4)
            {
            }
            column(Lbl5;Lbl5)
            {
            }
            column(Lbl6;Lbl6)
            {
            }
            column(MoneyInWords;MoneyInWords)
            {
            }
            column(Descr;Description)
            {
            }

            trigger OnAfterGetRecord();
            begin

                CompanyInfo.GET;
                CompanyAddress := CompanyInfo.Address + '-T.K.' + CompanyInfo."Post Code" + '-ΤΗΛ:' + CompanyInfo."Phone No." +
                                  '-ΦΑΞ:' + CompanyInfo."Fax No.";
                CompanyTaxData := 'ΑΦΜ:' + CompanyInfo."VAT Registration No." + '-ΔΟΥ:' + CompanyInfo."Tax Office" +
                                  '-Α.Μ.Α.Ε.' + CompanyInfo."Registration No.";

                if "Cust. Ledger Entry"."Customer No." <> '' then
                  Cust.GET("Cust. Ledger Entry"."Customer No.");


                if "Document Type" = "Document Type"::Payment then begin
                  PrintTitle := 'ΑΠΟΔΕΙΞΗ ΕΙΣΠΡΑΞΗΣ';
                  PrintTo := CompanyInfo.Name;
                  PrintFrom := Cust.Name;
                end else begin
                  PrintTitle := 'ΑΠΟΔΕΙΞΗ ΕΠΙΣΤΡΟΦΗΣ ΕΙΣΠΡΑΞΗΣ';
                  PrintTo := Cust.Name;
                  PrintFrom := CompanyInfo.Name;
                end;

                ABSAmount := ABS("Cust. Ledger Entry".Amount);

                MoneyInWords := General.GetMoneyToWords(ABSAmount);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        CompanyInfo : Record "Company Information";
        NoSeries : Record "No. Series";
        Cust : Record Customer;
        CompanyAddress : Text[150];
        CompanyTaxData : Text[150];
        MoneyInWords : Text[200];
        ABSAmount : Decimal;
        PrintTitle : Text[50];
        PrintTo : Text[50];
        PrintFrom : Text[50];
        Text032 : TextConst ELL='ΕΝΑ',ENU='ΕΝΑ';
        Text033 : TextConst ELL='ΔΥΟ',ENU='ΔΥΟ';
        Text034 : TextConst ELL='ΤΡΙΑ',ENU='ΤΡΙΑ';
        Text035 : TextConst ELL='ΤΕΣΣΕΡΑ',ENU='ΤΕΣΣΕΡΑ';
        Text036 : TextConst ELL='ΠΕΝΤΕ',ENU='ΠΕΝΤΕ';
        Text037 : TextConst ELL='ΕΞΙ',ENU='ΕΞΙ';
        Text038 : TextConst ELL='ΕΠΤΑ',ENU='ΕΠΤΑ';
        Text039 : TextConst ELL='ΟΚΤΩ',ENU='ΟΚΤΩ';
        Text040 : TextConst ELL='ΕΝΝΙΑ',ENU='ΕΝΝΙΑ';
        Text041 : TextConst ELL='ΔΕΚΑ',ENU='ΔΕΚΑ';
        Text042 : TextConst ELL='ΕΝΤΕΚΑ',ENU='ΕΝΤΕΚΑ';
        Text043 : TextConst ELL='ΔΩΔΕΚΑ',ENU='ΔΩΔΕΚΑ';
        Text044 : TextConst ELL='ΔΕΚΑΤΡΙΑ',ENU='ΔΕΚΑ';
        Text051 : TextConst ELL='ΕΙΚΟΣΙ',ENU='ΕΙΚΟΣΙ';
        Text052 : TextConst ELL='ΤΡΙΑΝΤΑ',ENU='ΤΡΙΑΝΤΑ';
        Text053 : TextConst ELL='ΣΑΡΑΝΤΑ',ENU='ΣΑΡΑΝΤΑ';
        Text054 : TextConst ELL='ΠΕΝΗΝΤΑ',ENU='ΠΕΝΗΝΤΑ';
        Text055 : TextConst ELL='ΕΞΗΝΤΑ',ENU='ΕΞΗΝΤΑ';
        Text056 : TextConst ELL='ΕΒΔΟΜΗΝΤΑ',ENU='ΕΒΔΟΜΗΝΤΑ';
        Text057 : TextConst ELL='ΟΓΔΟΝΤΑ',ENU='ΟΓΔΟΝΤΑ';
        Text058 : TextConst ELL='ΕΝΝΕΝΗΝΤΑ',ENU='ΕΝΕΝΗΝΤΑ';
        Text059 : TextConst ELL='ΧΙΛΙΑ',ENU='ΧΙΛΙΑ';
        Text060 : TextConst ELL='ΕΚΑΤΟΜΜΥΡΙΑ',ENU='MILLION';
        Text061 : TextConst ELL='ΔΙΣΕΚΑΤΟΜΜΥΡΙΑ',ENU='BILLION';
        Text070 : Label 'ΕΚΑΤΟ';
        Text071 : Label 'ΔΙΑΚΟΣΙΑ';
        Text072 : Label 'ΤΡΙΑΚΟΣΙΑ';
        Text073 : Label 'ΤΕΤΡΑΚΟΣΙΑ';
        Text074 : Label 'ΠΕΝΤΑΚΟΣΙΑ';
        Text075 : Label 'ΕΞΑΚΟΣΙΑ';
        Text076 : Label 'ΕΠΤΑΚΟΣΙΑ';
        Text077 : Label 'ΟΚΤΑΚΟΣΙΑ';
        Text078 : Label 'ΕΝΝΙΑΚΟΣΙΑ';
        Text024 : TextConst ELL='XXXX.XX',ENU='XXXX.XX';
        Text025 : TextConst ELL='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',ENU='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
        Text026 : TextConst ELL='ΜΗΔΕΝ',ENU='ZERO';
        Text027 : TextConst ELL='ΕΚΑΤΟ',ENU='HUNDRED';
        Text028 : TextConst ELL='ΚΑΙ',ENU='AND';
        Text029 : TextConst ELL='Το %1 έχει σαν αποτέλεσμα ένα μεγάλο αριθμό.',ENU='%1 results in a written number that is too long.';
        Text030 : TextConst ELL=' έχει ήδη συσχετιστεί με το  %1 %2 για τον πελάτη %3.',ENU=' is already applied to %1 %2 for customer %3.';
        Text031 : TextConst ELL=' έχει ήδη συσχετισθεί με %1 %2 για τον προμηθευτή %3.',ENU=' is already applied to %1 %2 for vendor %3.';
        LblNo : Label 'Αριθμός';
        LblDate : Label 'Ημερομηνία';
        Lbl1 : TextConst ELL='Ο υπογεγραμμένος',ENU='Undersigned';
        Lbl2 : TextConst ELL='έλαβα από τον/την κ.',ENU='received from mr/ms';
        Lbl3 : TextConst ELL='το ποσό των',ENU='the amount of';
        Lbl4 : TextConst ELL='για αιτιολογία',ENU='as a payment for';
        Lbl5 : TextConst ELL='ΣΥΝΟΛΟ ΜΕΤΡΗΤΩΝ',ENU='TOTAL AMOUNT';
        Lbl6 : TextConst ELL='Ο ΛΑΒΩΝ',ENU='Ο ΛΑΒΩΝ';
        General : Codeunit General;
}

