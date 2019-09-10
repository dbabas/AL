report 50012 "Posted Cheque Transact."
{
    // version IMP

    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Posted Cheque Transact.rdlc';

    dataset
    {
        dataitem("Posted Cheque Trans. Header";"Posted Cheque Trans. Header")
        {
            column(CompName;CompanyInfo.Name)
            {
            }
            column(CompProfession;CompanyInfo.Profession)
            {
            }
            column(CompAddress;CompanyAddress)
            {
            }
            column(CompTaxData;CompanyTaxData)
            {
            }
            column(RepTitle;RepTitle)
            {
            }
            column(LblNo;LblNo)
            {
            }
            column(LblDate;LblDate)
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
            column(Lbl7;Lbl7)
            {
            }
            column(Lbl8;Lbl8)
            {
            }
            column(Lbl9;Lbl9)
            {
            }
            column(Lbl10;Lbl10)
            {
            }
            column(Lbl11;Lbl11)
            {
            }
            column(PrintName;PrintName)
            {
            }
            column(PrintAddr;PrintAddr)
            {
            }
            column(PrintAFM;PrintAFM)
            {
            }
            column(PrintCity;PrintCity)
            {
            }
            column(PrintTel;PrintTel)
            {
            }
            column(FromTo;FromTo)
            {
            }
            column(DocNo;"No.")
            {
            }
            column(DocDate;"Document Date")
            {
            }
            column(PostDescr;"Posting Description")
            {
            }
            column(DocTotalAm;"Document Total Amount")
            {
            }
            dataitem("Posted Cheque Trans. Line";"Posted Cheque Trans. Line")
            {
                DataItemLink = "Document No."=FIELD("No.");
                column(ChequeNumber;"Cheque Number")
                {
                }
                column(ChequeBank;ChequeBank)
                {
                }
                column(ChequeValueDate;"Cheque Value Date")
                {
                }
                column(ChequeAmount;"Cheque Amount")
                {
                }
                column(MoneyInWords;MoneyInWords)
                {
                }

                trigger OnAfterGetRecord();
                begin

                    Cheque.SETRANGE("Cheque Number", "Cheque Number");
                    if Cheque.FIND('-') then begin
                      BAcc.GET(Cheque."Bank and Branch Code");
                      ChequeBank := BAcc.Name;
                    end;
                end;
            }
            dataitem("Posted Cheque Trans. Line2";"Posted Cheque Trans. Line")
            {
                DataItemLink = "Document No."=FIELD("No.");
            }

            trigger OnAfterGetRecord();
            begin

                CompanyInfo.GET;
                CompanyAddress := CompanyInfo.Address + '-T.K.' + CompanyInfo."Post Code" + '-ΤΗΛ:' + CompanyInfo."Phone No." +
                                  '-ΦΑΞ:' + CompanyInfo."Fax No.";
                CompanyTaxData := 'ΑΦΜ:' + CompanyInfo."VAT Registration No." + '-ΔΟΥ:' + CompanyInfo."Tax Office" +
                                  '-Α.Μ.Α.Ε.' + CompanyInfo."Registration No.";


                if "Posting Group Code"<>'' then begin
                 if CPNPostGroup.GET("Posting Group Code")then begin
                    RepTitle :=CPNPostGroup."Printing Description";
                 end;
                end;

                case CPNPostGroup."Delivery/Receipt" of
                  CPNPostGroup."Delivery/Receipt"::Receipt:
                  begin
                    FromTo := 'Από: ';
                //    RepTitle := 'ΑΠΟΔΕΙΞΗ ΠΑΡΑΛΑΒΗΣ ΕΠΙΤΑΓΩΝ';
                    PostedChequeTransLine.SETRANGE("Document No.", "No.");
                    if PostedChequeTransLine.FIND('-') then begin
                      if Cheque.GET(PostedChequeTransLine."No.") then  begin
                        if Cheque."Our Cheque" then begin
                          CPNPosition.SETRANGE(Position, "Next Position");
                          PrevCode := "Next Acc. No.";
                        end else begin
                          CPNPosition.SETRANGE(Position, "Previous Position");
                          PrevCode := PostedChequeTransLine."Previous Acc. No.";
                        end;
                      end;
                    end;
                    if CPNPosition.FIND('-') then begin
                      case CPNPosition.Type of
                        CPNPosition.Type::Customer:
                          GetCustomerData(PrevCode);
                        CPNPosition.Type::Vendor:
                          GetVendorData(PrevCode);
                        CPNPosition.Type::Lawyer:
                          GetLawyerData(PrevCode);
                        CPNPosition.Type::Bank:
                          GetBankData(NextCode);
                        CPNPosition.Type::"GL Account":
                          GetGLAccData(NextCode);
                      end;
                    end;
                  end;
                  CPNPostGroup."Delivery/Receipt"::Delivery:
                  begin
                    FromTo := 'Σε: ';
                //    RepTitle := 'ΠΙΝΑΚΙΟ ΜΕΤΑΒΙΒΑΣΗΣ ΕΠΙΤΑΓΩΝ';
                    PostedChequeTransLine.SETRANGE("Document No.", "No.");
                    if PostedChequeTransLine.FIND('-') then begin
                      if Cheque.GET(PostedChequeTransLine."No.") then  begin
                        if Cheque."Our Cheque" then begin
                          CPNPosition.SETRANGE(Position, "Previous Position");
                          NextCode := PostedChequeTransLine."Previous Acc. No.";
                        end else begin
                          CPNPosition.SETRANGE(Position, "Next Position");
                          NextCode := "Next Acc. No.";
                        end;
                      end;
                    end;
                    if CPNPosition.FIND('-') then begin
                      case CPNPosition.Type of
                        CPNPosition.Type::Customer:
                          GetCustomerData(NextCode);
                        CPNPosition.Type::Vendor:
                          GetVendorData(NextCode);
                        CPNPosition.Type::Lawyer:
                          GetLawyerData(NextCode);
                        CPNPosition.Type::Bank:
                          GetBankData(NextCode);
                        CPNPosition.Type::"GL Account":
                          GetGLAccData(NextCode);
                      end;
                    end;
                  end;
                end;

                MoneyInWords := General.GetMoneyToWords("Document Total Amount");
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
        CompanyAddress : Text[150];
        CompanyTaxData : Text[150];
        Vendor : Record Vendor;
        MoneyInWords : Text[200];
        ValMgmt : Codeunit "Document Management";
        ABSAmount : Decimal;
        FromTo : Text[100];
        TransType : Option "Παραλαβή","Μεταβίβαση";
        CPNPosition : Record "CPN Position";
        Customer : Record Customer;
        PrevCode : Code[20];
        Lawyer : Record "CPN Lawyer";
        PrintName : Text[100];
        PrintAddr : Text[100];
        PrintCity : Text[100];
        PrintTel : Text[100];
        PrintAFM : Text[100];
        PostedChequeTransLine : Record "Posted Cheque Trans. Line";
        Cheque : Record Cheque;
        ChequeBank : Text[30];
        RepTitle : Text[30];
        NextCode : Code[20];
        BankAccount : Record "Bank Account";
        GlAcc : Record "G/L Account";
        LblNo : Label 'Αριθμός';
        LblDate : Label 'Ημερομηνία';
        Lbl1 : Label 'Διεύθυνση:';
        Lbl2 : Label 'ΑΦΜ:';
        Lbl3 : Label 'Τηλ.:';
        Lbl4 : Label 'ΑΡ. ΕΠΙΤΑΓΗΣ';
        Lbl5 : Label 'ΤΡΑΠΕΖΑ';
        Lbl6 : Label 'ΗΜ/ΝΙΑ ΛΗΞΗΣ';
        Lbl7 : Label 'ΑΞΙΑ';
        Lbl8 : Label 'Αιτιολογία:';
        Lbl9 : Label 'Ολογράφως:';
        Lbl10 : Label 'ΣΥΝΟΛΟ';
        Lbl11 : Label 'Ο ΛΑΒΩΝ';
        CPNPostGroup : Record "CPN Posting Group";
        BAcc : Record "Bank Account";
        General : Codeunit General;

    procedure GetCustomerData(CodeIn : Code[20]);
    begin
        Customer.SETRANGE("No.", CodeIn);
        if Customer.FIND('-') then begin
          PrintName := Customer.Name;
          PrintAddr := Customer.Address;
          PrintCity := Customer.City;
          PrintTel := Customer."Phone No.";
          PrintAFM := Customer."VAT Registration No.";
        end;
    end;

    procedure GetVendorData(CodeIn : Code[20]);
    begin
        Vendor.SETRANGE("No.", CodeIn);
        if Vendor.FIND('-') then begin
          PrintName := Vendor.Name;
          PrintAddr := Vendor.Address;
          PrintCity := Vendor.City;
          PrintTel := Vendor."Phone No.";
          PrintAFM := Vendor."VAT Registration No.";
        end;
    end;

    procedure GetLawyerData(CodeIn : Code[20]);
    begin
        Lawyer.SETRANGE("No.", CodeIn);
        if Lawyer.FIND('-') then begin
          PrintName := Lawyer.Name;
          PrintAddr := Lawyer.Address;
          PrintCity := '';
          PrintTel := Lawyer.Phone;
          PrintAFM := '';
        end;
    end;

    procedure GetBankData(CodeIn : Code[20]);
    begin
        BankAccount.SETRANGE("No.", CodeIn);
        if BankAccount.FIND('-') then begin
          PrintName := BankAccount.Name;
          PrintAddr := BankAccount.Address;
          PrintCity := BankAccount.City;
          PrintTel := BankAccount."Phone No.";
          PrintAFM := '';
        end;
    end;

    procedure GetGLAccData(CodeIn : Code[20]);
    begin
        GlAcc.SETRANGE("No.", CodeIn);
        if GlAcc.FIND('-') then begin
          PrintName := GlAcc.Name;
          PrintAddr := '';
          PrintCity := '';
          PrintTel := '';
          PrintAFM := '';
        end;
    end;
}

