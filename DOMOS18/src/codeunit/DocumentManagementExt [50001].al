codeunit 50001 "Document Management Ext"
{
    // version NAVGR8.00,NAVGR9.00.46290,IMP

    // IMP-DB-06/06/16-Added "Description 2"
    // IMP-DB-15/06/16-Added "Net Weight"
    // IMP-DB-10/08/16-Fixed Purchase Order (Direct Unit Cost instead of Unit Cost)
    // IMP-DB-09/10/16-Added Quote option
    // IMP-DB-29/10/16-Added "Base Unit of Measure", "Quantity (Base)"


    trigger OnRun();
    begin
    end;

    var
        GLSetup : Record "General Ledger Setup";
        Language : Record Language;
        ReportSelection : Record "Report Selections";
        NoSeries : Record "No. Series";
        Location : Record Location;
        PaymentMethod : Record "Payment Method";
        ShipmentMethod : Record "Shipment Method";
        ReasonCode : Record "Reason Code";
        VAT_Pct : array [5] of Code[10];
        VAT_Net_Amount : array [5] of Decimal;
        VAT_Amount : array [5] of Decimal;
        TotalAddTax : Decimal;
        TaxEntry : Record "Tax Entry";
        GRText001 : TextConst ELL='Φόροι',ENU='Taxes';
        CPNSetup : Record "CPN Setup";
        CPNPostingSetup : Record "CPN Posting Group";
        BailmentLines : Record "Document Line" temporary;
        BailmentLastLineNo : Integer;
        PaymentTerms : Record "Payment Terms";
        SalespersonPurchaser : Record "Salesperson/Purchaser";
        GlobalDocNo : Code[20];
        HeaderSubType : Integer;
        General : Codeunit General;
        Item : Record Item;

    procedure CopyFromSalesHeader(SalesHeader : Record "Sales Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        SalesLine : Record "Sales Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        SalesComments : Record "Sales Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        InitBailment;
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := SalesHeader."No.";
        HeaderSubType := SalesHeader."Document Type";
        with SalesHeader do begin
          //IMP-DB-09/10/16 -
          if SalesHeader."Document Type"=SalesHeader."Document Type"::Quote then
            ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Quote")
          else
          //IMP-DB-09/10/16 +
            ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Order");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Sales Order";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          //IMP-DB-09/10/16 -
          if SalesHeader."Document Type"=SalesHeader."Document Type"::Quote then begin
            TmpDocumentHeader."Posting Date" := "Order Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          end else
          //IMP-DB-09/10/16 +
            TmpDocumentHeader."Posting Date" := "Posting Date";
            if ReportSelection."Print Time" then
              TmpDocumentHeader."Posting Time" := TIME;

          //IMP-DB-09/10/16 -
          if SalesHeader."Document Type"=SalesHeader."Document Type"::Quote then
            SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::Quote)
          else
          //IMP-DB-09/10/16 +
            SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::Order);
          SalesComments.SETRANGE("No." , "No.") ;
          if SalesComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := SalesComments.Comment;
            if SalesComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := SalesComments.Comment;
              if SalesComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := SalesComments.Comment;
                if SalesComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := SalesComments.Comment;
                  if SalesComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := SalesComments.Comment;
                end;
              end;
            end;
          end;
          Customer.GET("Sell-to Customer No.");
          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          TmpDocumentHeader."No." := "Sell-to Customer No.";
          TmpDocumentHeader.Name := "Sell-to Customer Name";
          TmpDocumentHeader."Name 2" := "Sell-to Customer Name 2";
          TmpDocumentHeader.Address := "Sell-to Address";
          TmpDocumentHeader."Address 2" := "Sell-to Address 2";
          TmpDocumentHeader.City := "Sell-to City";
          TmpDocumentHeader."Post Code" := "Sell-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Net Weight" := General.CalcSalesHeaderNetWeight(SalesHeader); //DOC-IMP-DB-15/06/16
          TmpDocumentHeader."Shipping Agent" := GetShippingAgent(SalesHeader."Shipping Agent Code"); //DOC-IMP-DB-29/10/16
          if ShipToAddress.GET("Sell-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          //IMP-DB-09/10/16 -
          if SalesHeader."Document Type"=SalesHeader."Document Type"::Quote then
            SalesLine.SETRANGE("Document Type", SalesLine."Document Type"::Quote)
          else
          //IMP-DB-09/10/16 +
            SalesLine.SETRANGE("Document Type", SalesLine."Document Type"::Order);
          SalesLine.SETRANGE("Document No.", "No.");
          if SalesLine.FINDSET then begin
            repeat
              if ((SalesLine.Type <> SalesLine.Type::" ")
              or ((SalesLine.Type = SalesLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity = 0))
              then begin
                if SalesLine.Bailment then begin
                  InsertBailment(SalesLine."Document No.",SalesLine."No.",SalesLine.Quantity,SalesLine."Unit Price",
                                 SalesLine.Amount,SalesLine."Amount Including VAT",SalesLine."Line Discount %",
                                 FORMAT(SalesLine."VAT %"),SalesLine."Unit of Measure",SalesLine.Description);
                  BailmentAmounts."Document No." := SalesLine."Document No.";
                  BailmentAmounts."Line No." := SalesLine."Line No.";
                  BailmentAmounts."Unit Of Measure" := SalesLine."Unit of Measure";
                  BailmentAmounts.Amount := BailmentAmounts.Amount + SalesLine.Amount;
                  BailmentAmounts.Quantity := BailmentAmounts.Quantity + SalesLine.Quantity;
                  BailmentAmounts."Amount After Discount" := BailmentAmounts."Amount After Discount" + SalesLine.Amount;
                  BailmentAmounts."VAT %" := FORMAT(SalesLine."VAT %");
                  BailmentAmounts."VAT Amount" := BailmentAmounts."VAT Amount"+(SalesLine."Amount Including VAT" - SalesLine.Amount);
                  BailmentAmounts."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT" + SalesLine."Amount Including VAT";
                  BailmentAmounts."Unit Of Measure" := SalesLine."Unit of Measure";
                  BailmentAmounts."No." := SalesLine."No.";
                  BailmentAmounts.Description := SalesLine.Description;
                  BailmentAmounts."Line Amount" := SalesLine."Line Amount";
                end else begin
                  TmpDocumentLine.INIT;
                  TmpDocumentLine."Document No." := SalesLine."Document No.";
                  TmpDocumentLine."Line No." := SalesLine."Line No.";
                  TmpDocumentLine.Type :=  SalesLine.Type;
                  TmpDocumentLine."No." := SalesLine."No.";
                  //DOC IMP-DB-06/06/16 -
                  //TmpDocumentLine.Description :=  SalesLine.Description;
                  TmpDocumentLine.Description :=  SalesLine.Description+' '+SalesLine."Description 2";
                  //DOC IMP-DB-06/06/16 +
                  TmpDocumentLine."Unit Of Measure" := SalesLine."Unit of Measure";
                  TmpDocumentLine.Quantity := SalesLine.Quantity ;
                  //IMP-DB-29/10/16 -
                  if (SalesLine.Type=SalesLine.Type::Item) and Item.GET(SalesLine."No.") then begin
                    TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                    TmpDocumentLine."Quantity (Base)" := SalesLine."Quantity (Base)";
                    IF NOT (SalesHeader."Sell-to Country/Region Code" IN ['GR','']) THEN
                      TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                  TmpDocumentLine."Unit Price" := SalesLine."Unit Price";
                  TmpDocumentLine.Amount := ROUND((SalesLine.Quantity * SalesLine."Unit Price"),
                                              GLSetup."Amount Rounding Precision");

                  TmpDocumentLine."Line Discount %" := SalesLine."Line Discount %";
                  TmpDocumentLine."Line Discount Amount" := SalesLine."Line Discount Amount";
                  TmpDocumentLine."Line Inv. Discount Amount" := SalesLine."Inv. Discount Amount";
                  TmpDocumentLine."Line Amount" := SalesLine."Line Amount";
                  TmpDocumentLine."Amount After Discount" := SalesLine.Amount;
                  TmpDocumentLine."VAT %" := FORMAT(SalesLine."VAT %");
                  TmpDocumentLine."VAT Amount" := SalesLine."Amount Including VAT" - SalesLine.Amount;
                  TmpDocumentLine."Amount Inc. VAT" := SalesLine."Amount Including VAT";
                  //Sumarize amounts
                  if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
                    ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                    ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                    ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                    ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" +
                      TmpDocumentLine."Amount After Discount";
                    ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                    ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end else begin
                    SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                    SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                    SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                    SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                    SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                    SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end;
                  TmpDocumentLine.INSERT;
                  CalculateVATDetails(TmpDocumentLine);
                end;
              end;
            until SalesLine.NEXT=0;
            if TmpDocumentLine.COUNT = 0 then begin
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
              TmpDocumentLine."Line No." := TmpDocumentLine."Line No." + 10000;
              TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
              TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
              TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
              TmpDocumentLine.Amount := BailmentAmounts.Amount;
              TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
              TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
              TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
              TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
              TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
              TmpDocumentLine.Bailment := true;
              CalculateVATDetails(TmpDocumentLine);
              SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
              SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
              SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
              SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
              SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
              SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
              SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
              SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
            end else begin
              if TmpDocumentLine.FINDLAST then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
                TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
                TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
                TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
                TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
                TmpDocumentLine.Amount := BailmentAmounts.Amount;
                TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
                TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
                TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
                TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
                TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
                TmpDocumentLine.Bailment := true;
                CalculateVATDetails(TmpDocumentLine);
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
              end;
            end;
          end;
          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT"+ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Maximum Bailments Per Page" := ReportSelection."Bailments Per Page";
          TmpDocumentHeader."Bailment No." := BailmentAmounts."No.";
          TmpDocumentHeader."Bailment Description" := BailmentAmounts.Description;
          TmpDocumentHeader."Bailment Unit Of Measure" := BailmentAmounts."Unit Of Measure";
          TmpDocumentHeader."Bailment Quantity" := TmpDocumentLine.Quantity;
          TmpDocumentHeader."Bailment Amount" := TmpDocumentLine.Amount;
          TmpDocumentHeader."Bailment Amount After Dicsount" := TmpDocumentLine."Amount After Discount";
          TmpDocumentHeader."Bailment Vat %" := TmpDocumentLine."VAT %";
          UpdateHeaderVatDetails(TmpDocumentHeader);
          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Sales Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader,TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromSalesInvoice(SalesInvHeader : Record "Sales Invoice Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        SalesInvLine : Record "Sales Invoice Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        SalesComments : Record "Sales Comment Line";
        CurrShipmentNo : Code[20];
        SalesShptHeader : Record "Sales Shipment Header";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        InitBailment;
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := SalesInvHeader."No.";
        with SalesInvHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Invoice");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Sales Invoice";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::"Posted Invoice");
          SalesComments.SETRANGE("No." , "No.") ;
          if SalesComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := SalesComments.Comment;
            if SalesComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := SalesComments.Comment;
              if SalesComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := SalesComments.Comment;
                if SalesComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := SalesComments.Comment;
                  if SalesComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := SalesComments.Comment;
                end;
              end;
            end;
          end;

          Customer.GET("Bill-to Customer No.");

          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Bill-to Customer No.";
          TmpDocumentHeader.Name := "Bill-to Name";
          TmpDocumentHeader."Name 2" := "Bill-to Name 2";
          TmpDocumentHeader.Address := "Bill-to Address";
          TmpDocumentHeader."Address 2" := "Bill-to Address 2";
          TmpDocumentHeader.City := "Bill-to City";
          TmpDocumentHeader."Post Code" := "Bill-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Shipping Agent" := GetShippingAgent("Shipping Agent Code"); //DOC-IMP-DB-29/10/16
          if ShipToAddress.GET("Bill-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          SalesInvLine.SETCURRENTKEY("Shipment No.","Shipment Line No.");
          SalesInvLine.SETRANGE("Document No.", "No.");
          if SalesInvLine.FINDSET then begin
            repeat
              if ((SalesInvLine.Type <> SalesInvLine.Type::" ")
              or ((SalesInvLine.Type = SalesInvLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((SalesInvLine.Type = SalesInvLine.Type::Item) and (SalesInvLine.Quantity = 0))
              then begin
                if SalesInvLine.Bailment then begin
                  InsertBailment(SalesInvLine."Document No.",SalesInvLine."No.",SalesInvLine.Quantity,SalesInvLine."Unit Price",
                                 SalesInvLine.Amount,SalesInvLine."Amount Including VAT",SalesInvLine."Line Discount %",
                                 FORMAT(SalesInvLine."VAT %"),SalesInvLine."Unit of Measure",SalesInvLine.Description);
                  BailmentAmounts."Document No." := SalesInvLine."Document No.";
                  BailmentAmounts."Line No." :=   SalesInvLine."Line No.";
                  BailmentAmounts.Amount := BailmentAmounts.Amount +SalesInvLine.Amount;
                  BailmentAmounts.Quantity := BailmentAmounts.Quantity +SalesInvLine.Quantity;
                  BailmentAmounts."Amount After Discount" := BailmentAmounts."Amount After Discount" + SalesInvLine.Amount;
                  BailmentAmounts."VAT %" := FORMAT(SalesInvLine."VAT %");
                  BailmentAmounts."VAT Amount" := BailmentAmounts."VAT Amount"+(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount);
                  BailmentAmounts."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT" +SalesInvLine."Amount Including VAT";
                  BailmentAmounts."Unit Of Measure" := SalesInvLine."Unit of Measure";
                  BailmentAmounts."No." := SalesInvLine."No.";
                  BailmentAmounts.Description :=  SalesInvLine.Description;
                  BailmentAmounts."Unit Price" := SalesInvLine."Unit Price";
                  BailmentAmounts."Line Discount %" := SalesInvLine."Line Discount %";
                  BailmentAmounts."Line Amount" := SalesInvLine."Line Amount";
                end else begin
                  TmpDocumentLine.INIT;
                  TmpDocumentLine."Document No." := SalesInvLine."Document No.";
                  TmpDocumentLine."Line No." :=   SalesInvLine."Line No.";
                  TmpDocumentLine.Type :=  SalesInvLine.Type;
                  TmpDocumentLine."No." := SalesInvLine."No.";
                  //DOC IMP-DB-06/06/16 -
                  //TmpDocumentLine.Description :=  SalesInvLine.Description;
                  TmpDocumentLine.Description :=  SalesInvLine.Description+' '+SalesInvLine."Description 2";
                  //DOC IMP-DB-06/06/16 +
                  TmpDocumentLine."Unit Of Measure" := SalesInvLine."Unit of Measure";
                  TmpDocumentLine.Quantity:= SalesInvLine.Quantity ;
                  //IMP-DB-29/10/16 -
                  if (SalesInvLine.Type=SalesInvLine.Type::Item) and Item.GET(SalesInvLine."No.") then begin
                    TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                    TmpDocumentLine."Quantity (Base)" := SalesInvLine."Quantity (Base)";
                    IF NOT (SalesInvHeader."Sell-to Country/Region Code" IN ['GR','']) THEN
                     TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                  TmpDocumentLine."Unit Price" := SalesInvLine."Unit Price";
                  TmpDocumentLine.Amount := ROUND((SalesInvLine.Quantity * SalesInvLine."Unit Price"),
                                              GLSetup."Amount Rounding Precision");

                  TmpDocumentLine."Line Discount %" := SalesInvLine."Line Discount %";
                  TmpDocumentLine."Line Discount Amount" := SalesInvLine."Line Discount Amount";
                  TmpDocumentLine."Line Inv. Discount Amount" := SalesInvLine."Inv. Discount Amount";
                  TmpDocumentLine."Line Amount" := SalesInvLine."Line Amount";
                  TmpDocumentLine."Amount After Discount" := SalesInvLine.Amount;
                  TmpDocumentLine."VAT %" := FORMAT(SalesInvLine."VAT %");
                  TmpDocumentLine."VAT Amount" := (SalesInvLine."Amount Including VAT" - SalesInvLine.Amount);
                  TmpDocumentLine."Amount Inc. VAT" := SalesInvLine."Amount Including VAT";
                  //Sumarize amounts
                  if SalesInvLine.Type = SalesInvLine.Type::"Charge (Item)" then begin
                    ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                    ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                    ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                    ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" +
                      TmpDocumentLine."Amount After Discount";
                    ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                    ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end else begin
                    SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                    SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                    SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                    SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                    SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                    SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end;
                  TmpDocumentLine.INSERT;
                  CalculateVATDetails(TmpDocumentLine);
                end;
                if (SalesInvHeader."Cancellation Type" = SalesInvHeader."Cancellation Type"::" ") and
                   (SalesInvHeader."Operation Type" = SalesInvHeader."Operation Type"::Invoice) and
                   (SalesInvLine."Shipment No." <> '') and
                   (SalesInvLine."Shipment No." <> CurrShipmentNo)
                then begin
                  CurrShipmentNo := SalesInvLine."Shipment No.";
                  if (STRLEN(TmpRelDocLine.Description + SalesInvLine."Shipment No." + ', ') >
                      MAXSTRLEN(TmpRelDocLine.Description)) or
                     (TmpRelDocLine.Description = '')
                  then begin
                    TmpRelDocLine.INIT;
                    TmpRelDocLine."Document No." := SalesInvHeader."No.";
                    TmpRelDocLine."Line No." := SalesInvLine."Line No.";
                    TmpRelDocLine.Description := SalesInvLine."Shipment No.";
                    TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                    TmpRelDocLine.INSERT;
                  end else begin
                    TmpRelDocLine.Description += ', ' + SalesInvLine."Shipment No.";
                    TmpRelDocLine.MODIFY;
                  end;
                end;

              end;
            until SalesInvLine.NEXT=0;

            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Sales);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                if TaxEntry."Credit Amount" then begin
                  TmpDocumentLine.Amount := TaxEntry.Amount * (-1);
                  TmpDocumentLine."VAT Amount" := TaxEntry."VAT Amount" * (-1);
                  SumAmount."Amount Inc. VAT" += TaxEntry."Amount Including VAT" * (-1);
                  TmpDocumentHeader."Document Tax Amount" += TaxEntry.Amount * (-1);
                  TmpDocumentHeader."Document Tax VAT Amount" += TaxEntry."VAT Amount" * (-1);
                end else begin
                  TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                  TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                  SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                  TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                  TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                end;
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;
            TmpDocumentLine.SETRANGE("Document No.",SalesInvHeader."No.");
            if TmpDocumentLine.COUNT = 0 then begin
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
              TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
              TmpDocumentLine.INSERT;
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
              TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
              TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
              TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
              TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
              TmpDocumentLine.Amount := BailmentAmounts.Amount;
              TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
              TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
              TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
              TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
              TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
              TmpDocumentLine.Bailment := true;
              CalculateVATDetails(TmpDocumentLine);
              SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
              SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
              SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
              SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
              SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
              SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
              SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
              SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
            end else begin
              if TmpDocumentLine.FINDLAST then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
                TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
                TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
                TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
                TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
                TmpDocumentLine.Amount := BailmentAmounts.Amount;
                TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
                TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
                TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
                TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
                TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
                TmpDocumentLine.Bailment := true;
                CalculateVATDetails(TmpDocumentLine);
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
              end;
            end;
          end;
          if SalesInvHeader."Cancellation Type" <> SalesInvHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := SalesInvHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := SalesInvHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (SalesInvHeader."Order No." <> '') and
               (SalesInvHeader."Operation Type" = SalesInvHeader."Operation Type"::Invoice)
            then begin
              SalesShptHeader.RESET;
              SalesShptHeader.SETCURRENTKEY("Order No.");
              SalesShptHeader.SETRANGE("Order No.",SalesInvHeader."Order No.");
              if SalesShptHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + SalesShptHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := SalesInvHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := SalesShptHeader."No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + SalesShptHeader."No.";
                  TmpRelDocLine.MODIFY;
                end;
              until SalesShptHeader.NEXT=0;
            end;
          end;

          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT"+ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Maximum Bailments Per Page" := ReportSelection."Bailments Per Page";
          TmpDocumentHeader."Bailment No." := BailmentAmounts."No.";
          TmpDocumentHeader."Bailment Description" := BailmentAmounts.Description;
          TmpDocumentHeader."Bailment Unit Of Measure" := BailmentAmounts."Unit Of Measure";
          TmpDocumentHeader."Bailment Quantity" := TmpDocumentLine.Quantity;
          TmpDocumentHeader."Bailment Amount" := TmpDocumentLine.Amount;
          TmpDocumentHeader."Bailment Amount After Dicsount" := TmpDocumentLine."Amount After Discount";
          TmpDocumentHeader."Bailment Vat %" := TmpDocumentLine."VAT %";
          TmpDocumentHeader."Bailment Unit Price" := BailmentAmounts."Unit Price";
          TmpDocumentHeader."Bailment Line Discount" := BailmentAmounts."Line Discount %";
          UpdateHeaderVatDetails(TmpDocumentHeader);
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"+";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Sales Invoice Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromSalesCreditMemo(SalesCrMemoHeader : Record "Sales Cr.Memo Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        SalesCrMemoLine : Record "Sales Cr.Memo Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        SalesComments : Record "Sales Comment Line";
        CurrRetReceiptNo : Code[20];
        RetRcptHeader : Record "Return Receipt Header";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        InitBailment;
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := SalesCrMemoHeader."No.";
        with SalesCrMemoHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Cr.Memo");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Sales Credit Memo";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::"Posted Credit Memo");
          SalesComments.SETRANGE("No." , "No.") ;
          if SalesComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := SalesComments.Comment;
            if SalesComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := SalesComments.Comment;
              if SalesComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := SalesComments.Comment;
                if SalesComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := SalesComments.Comment;
                  if SalesComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := SalesComments.Comment;
                end;
              end;
            end;
          end;

          Customer.GET("Bill-to Customer No.");

          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Bill-to Customer No.";
          TmpDocumentHeader.Name := "Bill-to Name";
          TmpDocumentHeader."Name 2" := "Bill-to Name 2";
          TmpDocumentHeader.Address := "Bill-to Address";
          TmpDocumentHeader."Address 2" := "Bill-to Address 2";
          TmpDocumentHeader.City := "Bill-to City";
          TmpDocumentHeader."Post Code" := "Bill-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Bill-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";

          TmpDocumentHeader."Location Address" := "Sell-to Address";

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          SalesCrMemoLine.SETCURRENTKEY("Return Receipt No.","Return Receipt Line No.");
          SalesCrMemoLine.SETRANGE("Document No.", "No.");
          if SalesCrMemoLine.FINDSET then begin
            repeat
              if ((SalesCrMemoLine.Type <> SalesCrMemoLine.Type::" ")
              or ((SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item) and (SalesCrMemoLine.Quantity = 0))
              then begin
                if SalesCrMemoLine.Bailment then begin
                  InsertBailment(SalesCrMemoLine."Document No.",SalesCrMemoLine."No.",SalesCrMemoLine.Quantity,SalesCrMemoLine.
        "Unit Price",
                                 SalesCrMemoLine.Amount,SalesCrMemoLine."Amount Including VAT",SalesCrMemoLine."Line Discount %",
                                 FORMAT(SalesCrMemoLine."VAT %"),SalesCrMemoLine."Unit of Measure",SalesCrMemoLine.Description);
                  BailmentAmounts."Document No." := SalesCrMemoLine."Document No.";
                  BailmentAmounts."Line No." :=   SalesCrMemoLine."Line No.";
                  BailmentAmounts.Amount := BailmentAmounts.Amount +SalesCrMemoLine.Amount;
                  BailmentAmounts.Quantity := BailmentAmounts.Quantity +SalesCrMemoLine.Quantity;
                  BailmentAmounts."Amount After Discount" := BailmentAmounts."Amount After Discount" + SalesCrMemoLine.Amount;
                  BailmentAmounts."VAT %" := FORMAT(SalesCrMemoLine."VAT %");
                  BailmentAmounts."VAT Amount" := BailmentAmounts."VAT Amount"+
                                                 (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount);
                  BailmentAmounts."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT" +SalesCrMemoLine."Amount Including VAT";
                  BailmentAmounts."Unit Of Measure" := SalesCrMemoLine."Unit of Measure";
                  BailmentAmounts."No." := SalesCrMemoLine."No.";
                  BailmentAmounts.Description :=  SalesCrMemoLine.Description;
                  BailmentAmounts."Unit Price" := SalesCrMemoLine."Unit Price";
                  BailmentAmounts."Line Discount %" := SalesCrMemoLine."Line Discount %";
                  BailmentAmounts."Line Amount" := SalesCrMemoLine."Line Amount";
                end else begin
                  TmpDocumentLine.INIT;
                  TmpDocumentLine."Document No." := SalesCrMemoLine."Document No.";
                  TmpDocumentLine."Line No." :=   SalesCrMemoLine."Line No.";
                  TmpDocumentLine.Type :=  SalesCrMemoLine.Type;
                  TmpDocumentLine."No." := SalesCrMemoLine."No.";
                  //DOC IMP-DB-06/06/16 -
                  //TmpDocumentLine.Description :=  SalesCrMemoLine.Description;
                  TmpDocumentLine.Description :=  SalesCrMemoLine.Description+' '+SalesCrMemoLine."Description 2";
                  //DOC IMP-DB-06/06/16 +
                  TmpDocumentLine."Unit Of Measure" := SalesCrMemoLine."Unit of Measure";
                  TmpDocumentLine.Quantity:= SalesCrMemoLine.Quantity ;
                  //IMP-DB-29/10/16 -
                  if (SalesCrMemoLine.Type=SalesCrMemoLine.Type::Item) and Item.GET(SalesCrMemoLine."No.") then begin
                    TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                    TmpDocumentLine."Quantity (Base)" := SalesCrMemoLine."Quantity (Base)";
                    IF NOT (SalesCrMemoHeader."Sell-to Country/Region Code" IN ['GR','']) THEN
                     TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                  TmpDocumentLine."Unit Price" := SalesCrMemoLine."Unit Price";
                  TmpDocumentLine.Amount := ROUND((SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price"),
                                              GLSetup."Amount Rounding Precision");

                  TmpDocumentLine."Line Discount %" := SalesCrMemoLine."Line Discount %";
                  TmpDocumentLine."Line Discount Amount" := SalesCrMemoLine."Line Discount Amount";
                  TmpDocumentLine."Line Inv. Discount Amount" := SalesCrMemoLine."Inv. Discount Amount";
                  TmpDocumentLine."Line Amount" := SalesCrMemoLine."Line Amount";
                  TmpDocumentLine."Amount After Discount" := SalesCrMemoLine.Amount;
                  TmpDocumentLine."VAT %" := FORMAT(SalesCrMemoLine."VAT %");
                  TmpDocumentLine."VAT Amount" := (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount);
                  TmpDocumentLine."Amount Inc. VAT" := SalesCrMemoLine."Amount Including VAT";
                  //Sumarize amounts
                  if SalesCrMemoLine.Type = SalesCrMemoLine.Type::"Charge (Item)" then begin
                    ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                    ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                    ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                    ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" +
                      TmpDocumentLine."Amount After Discount";
                    ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                    ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end else begin
                    SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                    SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                    SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                    SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                    SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                    SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                    SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                    SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                  end;
                  TmpDocumentLine.INSERT;
                  CalculateVATDetails(TmpDocumentLine);
                end;
                if (SalesCrMemoHeader."Cancellation Type" = SalesCrMemoHeader."Cancellation Type"::" ") and
                   (SalesCrMemoHeader."Operation Type" = SalesCrMemoHeader."Operation Type"::Invoice) and
                   (SalesCrMemoLine."Return Receipt No." <> '') and
                   (SalesCrMemoLine."Return Receipt No." <> CurrRetReceiptNo)
                then begin
                  CurrRetReceiptNo := SalesCrMemoLine."Return Receipt No.";
                  if (STRLEN(TmpRelDocLine.Description + SalesCrMemoLine."Return Receipt No." + ', ') >
                      MAXSTRLEN(TmpRelDocLine.Description)) or
                     (TmpRelDocLine.Description = '')
                  then begin
                    TmpRelDocLine.INIT;
                    TmpRelDocLine."Document No." := SalesCrMemoHeader."No.";
                    TmpRelDocLine."Line No." := SalesCrMemoLine."Line No.";
                    TmpRelDocLine.Description := SalesCrMemoLine."Return Receipt No.";
                    TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                    TmpRelDocLine.INSERT;
                  end else begin
                    TmpRelDocLine.Description += ', ' + SalesCrMemoLine."Return Receipt No.";
                    TmpRelDocLine.MODIFY;
                  end;
                end;

              end;
            until SalesCrMemoLine.NEXT=0;

            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Sales);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                if TaxEntry."Credit Amount" then begin
                  TmpDocumentLine.Amount := TaxEntry.Amount;
                  TmpDocumentLine."VAT Amount" := TaxEntry."VAT Amount";
                  SumAmount."Amount Inc. VAT" += TaxEntry."Amount Including VAT";
                  TmpDocumentHeader."Document Tax Amount" += TaxEntry.Amount;
                  TmpDocumentHeader."Document Tax VAT Amount" += TaxEntry."VAT Amount";
                end else begin
                  TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                  TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                  SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                  TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                  TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                end;
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;
            TmpDocumentLine.SETRANGE("Document No.",SalesCrMemoHeader."No.");
            if TmpDocumentLine.COUNT =0 then begin
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
              TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
              TmpDocumentLine.INSERT;
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
              TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
              TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
              TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
              TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
              TmpDocumentLine.Amount := BailmentAmounts.Amount;
              TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
              TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
              TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
              TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
              TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
              TmpDocumentLine.Bailment := true;
              CalculateVATDetails(TmpDocumentLine);
              SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
              SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
              SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
              SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
              SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
              SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
              SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
              SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
            end else begin
              if TmpDocumentLine.FINDLAST then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
                TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
                TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
                TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
                TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
                TmpDocumentLine.Amount := BailmentAmounts.Amount;
                TmpDocumentLine."VAT %" := BailmentAmounts."VAT %";
                TmpDocumentLine."VAT Amount" := BailmentAmounts."VAT Amount";
                TmpDocumentLine."Amount After Discount" := BailmentAmounts."Amount After Discount";
                TmpDocumentLine."Amount Inc. VAT" := BailmentAmounts."Amount Inc. VAT";
                TmpDocumentLine."Line Amount" := BailmentAmounts."Line Amount";
                TmpDocumentLine.Bailment := true;
                CalculateVATDetails(TmpDocumentLine);
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
              end;
            end;
          end;
          if SalesCrMemoHeader."Cancellation Type" <> SalesCrMemoHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := SalesCrMemoHeader."No.";
            TmpRelDocLine."Line No." := 10000;
            TmpRelDocLine.Description := SalesCrMemoHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (SalesCrMemoHeader."Return Order No." <> '') and
               (SalesCrMemoHeader."Operation Type" = SalesCrMemoHeader."Operation Type"::Invoice)
            then begin
              RetRcptHeader.RESET;
              RetRcptHeader.SETCURRENTKEY("Return Order No.");
              RetRcptHeader.SETRANGE("Return Order No.",SalesCrMemoHeader."Return Order No.");
              if RetRcptHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + RetRcptHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := SalesCrMemoHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := RetRcptHeader."No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + RetRcptHeader."No.";
                  TmpRelDocLine.MODIFY;
                end;
              until RetRcptHeader.NEXT=0;
            end;
          end;
          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" +
                                             (SumAmount."Amount Inc. VAT" + ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Maximum Bailments Per Page" := ReportSelection."Bailments Per Page";
          TmpDocumentHeader."Bailment No." := BailmentAmounts."No.";
          TmpDocumentHeader."Bailment Description" := BailmentAmounts.Description;
          TmpDocumentHeader."Bailment Unit Of Measure" := BailmentAmounts."Unit Of Measure";
          TmpDocumentHeader."Bailment Quantity" := TmpDocumentLine.Quantity;
          TmpDocumentHeader."Bailment Amount" := TmpDocumentLine.Amount;
          TmpDocumentHeader."Bailment Amount After Dicsount" := TmpDocumentLine."Amount After Discount";
          TmpDocumentHeader."Bailment Vat %" := TmpDocumentLine."VAT %";
          TmpDocumentHeader."Bailment Unit Price" := BailmentAmounts."Unit Price";
          TmpDocumentHeader."Bailment Line Discount" := BailmentAmounts."Line Discount %";
          UpdateHeaderVatDetails(TmpDocumentHeader);
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"-";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Sales Cr.Memo Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromSalesShipment(SalesShptHeader : Record "Sales Shipment Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        SalesShptLine : Record "Sales Shipment Line";
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        SalesComments : Record "Sales Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        InitBailment;
        GlobalDocNo := SalesShptHeader."No.";
        with SalesShptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Shipment");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Sales Shipment";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::Shipment);
          SalesComments.SETRANGE("No." , "No.") ;
          if SalesComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := SalesComments.Comment;
            if SalesComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := SalesComments.Comment;
              if SalesComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := SalesComments.Comment;
                if SalesComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := SalesComments.Comment;
                  if SalesComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := SalesComments.Comment;
                end;
              end;
            end;
          end;

          Customer.GET("Sell-to Customer No.");

          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Sell-to Customer No.";
          TmpDocumentHeader.Name := "Sell-to Customer Name";
          TmpDocumentHeader."Name 2" := "Sell-to Customer Name 2";
          TmpDocumentHeader.Address := "Sell-to Address";
          TmpDocumentHeader."Address 2" := "Sell-to Address 2";
          TmpDocumentHeader.City := "Sell-to City";
          TmpDocumentHeader."Post Code" := "Sell-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Shipping Agent" := GetShippingAgent("Shipping Agent Code"); //DOC-IMP-DB-29/10/16
          if ShipToAddress.GET("Sell-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          SalesShptLine.SETRANGE("Document No.", "No.");
          if SalesShptLine.FINDSET then begin
            repeat
              if ((SalesShptLine.Type <> SalesShptLine.Type::" ")
              or ((SalesShptLine.Type = SalesShptLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((SalesShptLine.Type = SalesShptLine.Type::Item) and (SalesShptLine.Quantity = 0))
              then begin
                if SalesShptLine.Bailment then begin
                  InsertBailment(SalesShptLine."Document No.",SalesShptLine."No.",SalesShptLine.Quantity,
                                 0,0,0,0,'',SalesShptLine."Unit of Measure",SalesShptLine.Description);
                  BailmentAmounts."Document No." := SalesShptLine."Document No.";
                  BailmentAmounts."Line No." := SalesShptLine."Line No.";
                  BailmentAmounts.Quantity += SalesShptLine.Quantity;
                  BailmentAmounts."Unit Of Measure" := SalesShptLine."Unit of Measure";
                  BailmentAmounts."No." := SalesShptLine."No.";
                  BailmentAmounts.Description := SalesShptLine.Description;
                end else begin
                  TmpDocumentLine.INIT;
                  TmpDocumentLine."Document No." := SalesShptLine."Document No.";
                  TmpDocumentLine."Line No." :=   SalesShptLine."Line No.";
                  TmpDocumentLine.Type :=  SalesShptLine.Type;
                  TmpDocumentLine."No." := SalesShptLine."No.";
                  //DOC IMP-DB-06/06/16 -
                  //TmpDocumentLine.Description :=  SalesShptLine.Description;
                  TmpDocumentLine.Description :=  SalesShptLine.Description+' '+SalesShptLine."Description 2";
                  //DOC IMP-DB-06/06/16 +
                  TmpDocumentLine."Unit Of Measure" := SalesShptLine."Unit of Measure";
                  TmpDocumentLine.Quantity := SalesShptLine.Quantity ;
                  //IMP-DB-29/10/16 -
                  if (SalesShptLine.Type=SalesShptLine.Type::Item) and Item.GET(SalesShptLine."No.") then begin
                   TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                   TmpDocumentLine."Quantity (Base)" := SalesShptLine."Quantity (Base)";
                   IF NOT (SalesShptHeader."Sell-to Country/Region Code" IN ['GR','']) THEN
                     TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                  TmpDocumentHeader."Total Quantity"  += SalesShptLine.Quantity;
                  TmpDocumentLine.INSERT;
                end;
              end;
            until SalesShptLine.NEXT=0;
          end;
          if SalesShptHeader."Cancellation Type" <> SalesShptHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := SalesShptHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := SalesShptHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;
          TmpDocumentLine.SETRANGE("Document No.",SalesShptHeader."No.");
          if TmpDocumentLine.COUNT = 0 then begin
            TmpDocumentLine.INIT;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." := TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine.INSERT;
            TmpDocumentLine.FINDLAST;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
            TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
            TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
            TmpDocumentLine.Bailment := true;
          end else begin
            TmpDocumentLine.FINDLAST;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
            TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
            TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
            TmpDocumentLine.Bailment := true;
          end;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Maximum Bailments Per Page" := ReportSelection."Bailments Per Page";
          TmpDocumentHeader."Bailment No." := BailmentAmounts."No.";
          TmpDocumentHeader."Bailment Description" := BailmentAmounts.Description;
          TmpDocumentHeader."Bailment Unit Of Measure" := BailmentAmounts."Unit Of Measure";
          TmpDocumentHeader."Bailment Quantity" := TmpDocumentLine.Quantity;
          TmpDocumentHeader."Bailment Amount" := TmpDocumentLine.Amount;
          TmpDocumentHeader."Bailment Amount After Dicsount" := TmpDocumentLine."Amount After Discount";
          TmpDocumentHeader."Bailment Vat %" := TmpDocumentLine."VAT %";
          TmpDocumentHeader."Net Weight" := General.CalcSalesShipmentHeaderNetWeight(SalesShptHeader); //DOC-IMP-DB-15/06/16
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Sales Shipment Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromSalesReturnReceipt(ReturnReceiptHeader : Record "Return Receipt Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ReturnReceiptLine : Record "Return Receipt Line";
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        SalesComments : Record "Sales Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        InitBailment;
        GlobalDocNo := ReturnReceiptHeader."No.";
        with ReturnReceiptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Ret.Rcpt.");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Sales Return Receipt";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          SalesComments.SETRANGE("Document Type" , SalesComments."Document Type"::"Posted Return Receipt");
          SalesComments.SETRANGE("No." , "No.") ;
          if SalesComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := SalesComments.Comment;
            if SalesComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := SalesComments.Comment;
              if SalesComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := SalesComments.Comment;
                if SalesComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := SalesComments.Comment;
                  if SalesComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := SalesComments.Comment;
                end;
              end;
            end;
          end;

          Customer.GET("Sell-to Customer No.");

          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Sell-to Customer No.";
          TmpDocumentHeader.Name := "Sell-to Customer Name";
          TmpDocumentHeader."Name 2" := "Sell-to Customer Name 2";
          TmpDocumentHeader.Address := "Sell-to Address";
          TmpDocumentHeader."Address 2" := "Sell-to Address 2";
          TmpDocumentHeader.City := "Sell-to City";
          TmpDocumentHeader."Post Code" := "Sell-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Shipping Agent" := GetShippingAgent("Shipping Agent Code"); //DOC-IMP-DB-29/10/16
          if ShipToAddress.GET("Sell-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";

          TmpDocumentHeader."Location Address" := "Sell-to Address";

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;

          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ReturnReceiptLine.SETRANGE("Document No.", "No.");
          if ReturnReceiptLine.FINDSET then begin
            repeat
              if ((ReturnReceiptLine.Type <> ReturnReceiptLine.Type::" ")
              or ((ReturnReceiptLine.Type = ReturnReceiptLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ReturnReceiptLine.Type = ReturnReceiptLine.Type::Item) and (ReturnReceiptLine.Quantity = 0))
              then begin
                if ReturnReceiptLine.Bailment then begin
                  InsertBailment(ReturnReceiptLine."Document No.",ReturnReceiptLine."No.",ReturnReceiptLine.Quantity,
                                 0,0,0,0,'',ReturnReceiptLine."Unit of Measure",ReturnReceiptLine.Description);
                  BailmentAmounts."Document No." := ReturnReceiptLine."Document No.";
                  BailmentAmounts."Line No." := ReturnReceiptLine."Line No.";
                  BailmentAmounts.Quantity += ReturnReceiptLine.Quantity;
                  BailmentAmounts."Unit Of Measure" := ReturnReceiptLine."Unit of Measure";
                  BailmentAmounts."No." := ReturnReceiptLine."No.";
                  BailmentAmounts.Description := ReturnReceiptLine.Description;
                end else begin
                  TmpDocumentLine.INIT;
                  TmpDocumentLine."Document No." := ReturnReceiptLine."Document No.";
                  TmpDocumentLine."Line No." :=   ReturnReceiptLine."Line No.";
                  TmpDocumentLine.Type :=  ReturnReceiptLine.Type;
                  TmpDocumentLine."No." := ReturnReceiptLine."No.";
                  //DOC IMP-DB-06/06/16 -
                  //TmpDocumentLine.Description :=  ReturnReceiptLine.Description;
                  TmpDocumentLine.Description :=  ReturnReceiptLine.Description+' '+ReturnReceiptLine."Description 2";
                  //DOC IMP-DB-06/06/16 +
                  TmpDocumentLine."Unit Of Measure" := ReturnReceiptLine."Unit of Measure";
                  TmpDocumentLine.Quantity := ReturnReceiptLine.Quantity ;
                  //IMP-DB-29/10/16 -
                  if (ReturnReceiptLine.Type=ReturnReceiptLine.Type::Item) and Item.GET(ReturnReceiptLine."No.") then begin
                   TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                   TmpDocumentLine."Quantity (Base)" := ReturnReceiptLine."Quantity (Base)";
                   IF NOT (ReturnReceiptHeader."Sell-to Country/Region Code" IN ['GR','']) THEN
                     TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                  TmpDocumentHeader."Total Quantity"  += ReturnReceiptLine.Quantity;
                  TmpDocumentLine.INSERT;
                end;
              end;
            until ReturnReceiptLine.NEXT=0;
          end;

          if ReturnReceiptHeader."Cancellation Type" <> ReturnReceiptHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ReturnReceiptHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := ReturnReceiptHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;
          TmpDocumentLine.SETRANGE("Document No.",ReturnReceiptHeader."No.");
          if TmpDocumentLine.COUNT=0 then begin
            TmpDocumentLine.INIT;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine.INSERT;
            TmpDocumentLine.FINDLAST;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
            TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
            TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
            TmpDocumentLine.Bailment := true;
          end else begin
            TmpDocumentLine.FINDLAST;
            TmpDocumentLine.INIT;
            TmpDocumentLine."Document No." := BailmentAmounts."Document No.";
            TmpDocumentLine."Line No." :=   TmpDocumentLine."Line No."+ 10000;
            TmpDocumentLine."Unit Price" := BailmentAmounts."Unit Price";
            TmpDocumentLine."Unit Of Measure" := BailmentAmounts."Unit Of Measure";
            TmpDocumentLine.Quantity := BailmentAmounts.Quantity ;
            TmpDocumentLine.Bailment := true;
          end;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Maximum Bailments Per Page" := ReportSelection."Bailments Per Page";
          TmpDocumentHeader."Bailment No." := BailmentAmounts."No.";
          TmpDocumentHeader."Bailment Description" := BailmentAmounts.Description;
          TmpDocumentHeader."Bailment Unit Of Measure" := BailmentAmounts."Unit Of Measure";
          TmpDocumentHeader."Bailment Quantity" := TmpDocumentLine.Quantity;
          TmpDocumentHeader."Bailment Amount" := TmpDocumentLine.Amount;
          TmpDocumentHeader."Bailment Amount After Dicsount" := TmpDocumentLine."Amount After Discount";
          TmpDocumentHeader."Bailment Vat %" := TmpDocumentLine."VAT %";
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Return Receipt Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPurchHeader(PurchHeader : Record "Purchase Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        PurchLine : Record "Purchase Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Vendor : Record Vendor;
        PurchComments : Record "Purch. Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := PurchHeader."No.";
        HeaderSubType := PurchHeader."Document Type";
        with PurchHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"P.Order");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Purchase Order";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          PurchComments.SETRANGE("Document Type" , PurchComments."Document Type"::Order);
          PurchComments.SETRANGE("No." , "No.") ;
          if PurchComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := PurchComments.Comment;
            if PurchComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := PurchComments.Comment;
              if PurchComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := PurchComments.Comment;
                if PurchComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := PurchComments.Comment;
                  if PurchComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := PurchComments.Comment;
                end;
              end;
            end;
          end;

          Vendor.GET("Buy-from Vendor No.");

          if Language.GET(Vendor."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Buy-from Vendor No.";
          TmpDocumentHeader.Name := "Buy-from Vendor Name";
          TmpDocumentHeader."Name 2" := "Buy-from Vendor Name 2";
          TmpDocumentHeader.Address := "Buy-from Address";
          TmpDocumentHeader."Address 2" := "Buy-from Address 2";
          TmpDocumentHeader.City := "Buy-from City";
          TmpDocumentHeader."Post Code" := "Buy-from Post Code";
          TmpDocumentHeader.Phone := Vendor."Phone No.";
          TmpDocumentHeader.FAX := Vendor."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Vendor."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Vendor."Tax Office";
          TmpDocumentHeader.Profession := Vendor.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Location Code" := "Location Code";
          TmpDocumentHeader."Net Weight" := General.CalcPurchHeaderNetWeight(PurchHeader); //DOC-IMP-DB-15/06/16
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Purchaser Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          PurchLine.SETRANGE("Document Type", PurchLine."Document Type"::Order);
          PurchLine.SETRANGE("Document No.", "No.");
          if PurchLine.FINDSET then begin
            repeat
              if ((PurchLine.Type <> PurchLine.Type::" ")
              or ((PurchLine.Type = PurchLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((PurchLine.Type = PurchLine.Type::Item) and (PurchLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := PurchLine."Document No.";
                TmpDocumentLine."Line No." :=   PurchLine."Line No.";
                TmpDocumentLine.Type :=  PurchLine.Type;
                TmpDocumentLine."No." := PurchLine."No.";
                //DOC IMP-DB-06/06/16 -
                //TmpDocumentLine.Description :=  PurchLine.Description;
                TmpDocumentLine.Description :=  PurchLine.Description+' '+PurchLine."Description 2";
                //DOC IMP-DB-06/06/16 +
                TmpDocumentLine."Unit Of Measure" := PurchLine."Unit of Measure";
                TmpDocumentLine.Quantity := PurchLine.Quantity ;
                //IMP-DB-29/10/16 -
                  if (PurchLine.Type=PurchLine.Type::Item) and Item.GET(PurchLine."No.") then begin
                   TmpDocumentLine."Base Unit of Measure" := Item."Base Unit of Measure";
                   TmpDocumentLine."Quantity (Base)" := PurchLine."Quantity (Base)";
                   IF NOT (PurchHeader."Buy-from Country/Region Code" IN ['GR','']) THEN
                     TmpDocumentLine.Description := Item."Foreign Description";
                  end;
                  //IMP-DB-29/10/16 +
                //DOC IMP-DB-10/08/16 -
                //TmpDocumentLine."Unit Price" := PurchLine."Unit Cost";
                TmpDocumentLine."Unit Price" := PurchLine."Direct Unit Cost";
                //TmpDocumentLine.Amount := ROUND((PurchLine.Quantity * PurchLine."Unit Cost"),
                //                            GLSetup."Amount Rounding Precision");
                TmpDocumentLine.Amount := ROUND((PurchLine.Quantity * PurchLine."Direct Unit Cost"),
                                            GLSetup."Amount Rounding Precision");
                //DOC IMP-DB-10/08/16 +
                TmpDocumentLine."Line Discount %" := PurchLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := PurchLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := PurchLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := PurchLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := PurchLine.Amount;
                TmpDocumentLine."VAT %" := FORMAT(PurchLine."VAT %");
                TmpDocumentLine."VAT Amount" := (PurchLine."Outstanding Amount" - PurchLine."Line Amount");
                TmpDocumentLine."Amount Inc. VAT" := PurchLine."Outstanding Amount";
                //Sumarize amounts
                if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
                  ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                  ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                  ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                  ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" + TmpDocumentLine."Amount After Discount"
        ;
                  ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                  ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end else begin
                  SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                  SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                  SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                  SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                  SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                  SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end;
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              end;
            until PurchLine.NEXT=0;
          end;

          Vendor.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Vendor.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT"+ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";

          UpdateHeaderVatDetails(TmpDocumentHeader);
          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Purchase Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPurchInvoice(PurchInvHeader : Record "Purch. Inv. Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        PurchInvLine : Record "Purch. Inv. Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Vendor : Record Vendor;
        PurchComments : Record "Purch. Comment Line";
        CurrOrderNo : Code[20];
        PurchRcptHeader : Record "Purch. Rcpt. Header";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := PurchInvHeader."No.";
        with PurchInvHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"P.Invoice");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Purchase Invoice";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          PurchComments.SETRANGE("Document Type" , PurchComments."Document Type"::"Posted Invoice");
          PurchComments.SETRANGE("No." , "No.") ;
          if PurchComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := PurchComments.Comment;
            if PurchComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := PurchComments.Comment;
              if PurchComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := PurchComments.Comment;
                if PurchComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := PurchComments.Comment;
                  if PurchComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := PurchComments.Comment;
                end;
              end;
            end;
          end;
          Vendor.GET("Pay-to Vendor No.");

          if Language.GET(Vendor."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Pay-to Vendor No.";
          TmpDocumentHeader.Name := "Pay-to Name";
          TmpDocumentHeader."Name 2" := "Pay-to Name 2";
          TmpDocumentHeader.Address := "Pay-to Address";
          TmpDocumentHeader."Address 2" := "Pay-to Address 2";
          TmpDocumentHeader.City := "Pay-to City";
          TmpDocumentHeader."Post Code" := "Pay-to Post Code";
          TmpDocumentHeader.Phone := Vendor."Phone No.";
          TmpDocumentHeader.FAX := Vendor."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Vendor."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Vendor."Tax Office";
          TmpDocumentHeader.Profession := Vendor.Profession;
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Purchaser Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          PurchInvLine.SETCURRENTKEY("Order No.");
          PurchInvLine.SETRANGE("Document No.", "No.");
          if PurchInvLine.FINDSET then begin
            repeat
              if ((PurchInvLine.Type <> PurchInvLine.Type::" ")
              or ((PurchInvLine.Type = PurchInvLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((PurchInvLine.Type = PurchInvLine.Type::Item) and (PurchInvLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := PurchInvLine."Document No.";
                TmpDocumentLine."Line No." :=   PurchInvLine."Line No.";
                TmpDocumentLine.Type :=  PurchInvLine.Type;
                TmpDocumentLine."No." := PurchInvLine."No.";
                //DOC IMP-DB-06/06/16 -
                //TmpDocumentLine.Description :=  PurchInvLine.Description;
                TmpDocumentLine.Description :=  PurchInvLine.Description+' '+PurchInvLine."Description 2";
                //DOC IMP-DB-06/06/16 +
                TmpDocumentLine."Unit Of Measure" :=PurchInvLine."Unit of Measure";
                TmpDocumentLine.Quantity:= PurchInvLine.Quantity ;
                TmpDocumentLine."Unit Price" := PurchInvLine."Unit Cost";
                TmpDocumentLine.Amount := ROUND((PurchInvLine.Quantity * PurchInvLine."Unit Cost"),GLSetup."Amount Rounding Precision");
                TmpDocumentLine."Line Discount %" := PurchInvLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := PurchInvLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := PurchInvLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := PurchInvLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := PurchInvLine.Amount;
                TmpDocumentLine."VAT %" :=  FORMAT(PurchInvLine."VAT %");
                TmpDocumentLine."VAT Amount" := (PurchInvLine."Amount Including VAT" - PurchInvLine.Amount);
                TmpDocumentLine."Amount Inc. VAT" := PurchInvLine."Amount Including VAT";
                //Sumarize amounts
                if PurchInvLine.Type = PurchInvLine.Type::"Charge (Item)" then begin
                  ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                  ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                  ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                  ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                  ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                  ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end else begin
                  SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                  SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                  SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                  SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                  SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                  SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end;
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
                if (PurchInvHeader."Cancellation Type" = PurchInvHeader."Cancellation Type"::" ") and
                   (PurchInvHeader."Operation Type" = PurchInvHeader."Operation Type"::Invoice) and
                   (PurchInvLine."Order No." <> '') and
                   (PurchInvLine."Order No." <> CurrOrderNo)
                then begin
                  CurrOrderNo := PurchInvLine."Order No.";
                  PurchRcptHeader.RESET;
                  PurchRcptHeader.SETCURRENTKEY("Order No.");
                  PurchRcptHeader.SETRANGE("Order No.",CurrOrderNo);
                  if PurchRcptHeader.FINDFIRST then begin
                    if (STRLEN(TmpRelDocLine.Description + PurchRcptHeader."No." + ', ') >
                        MAXSTRLEN(TmpRelDocLine.Description)) or
                       (TmpRelDocLine.Description = '')
                    then begin
                      TmpRelDocLine.INIT;
                      TmpRelDocLine."Document No." := PurchInvHeader."No.";
                      TmpRelDocLine."Line No." := PurchInvLine."Line No.";
                      TmpRelDocLine.Description := PurchRcptHeader."No.";
                      TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                      TmpRelDocLine.INSERT;
                    end else begin
                      TmpRelDocLine.Description += ', ' + PurchRcptHeader."No.";
                      TmpRelDocLine.MODIFY;
                    end;
                  end;
                end;
              end;
            until PurchInvLine.NEXT=0;

            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Purchases);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;

          end;

          if PurchInvHeader."Cancellation Type" <> PurchInvHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := PurchInvHeader."No.";
            TmpRelDocLine."Line No." := 10000;
            TmpRelDocLine.Description := PurchInvHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (PurchInvHeader."Order No." <> '') and
               (PurchInvHeader."Operation Type" = PurchInvHeader."Operation Type"::Invoice)
            then begin
              PurchRcptHeader.RESET;
              PurchRcptHeader.SETCURRENTKEY("Order No.");
              PurchRcptHeader.SETRANGE("Order No.",PurchInvHeader."Order No.");
              if PurchRcptHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + PurchRcptHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := PurchInvHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := PurchRcptHeader."No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + PurchRcptHeader."No.";
                  TmpRelDocLine.MODIFY;
                end;
              until PurchRcptHeader.NEXT=0;
            end;
          end;
          Vendor.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Vendor.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT" + ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          UpdateHeaderVatDetails(TmpDocumentHeader);
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"-";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Purch. Inv. Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader,TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPurchCreditMemo(PurchCrMemoHeader : Record "Purch. Cr. Memo Hdr.";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        PurchCrMemoLine : Record "Purch. Cr. Memo Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Vendor : Record Vendor;
        PurchComments : Record "Purch. Comment Line";
        CurrRetOrderNo : Code[20];
        RetShptHeader : Record "Return Shipment Header";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        GlobalDocNo := PurchCrMemoHeader."No.";
        with PurchCrMemoHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"P.Cr.Memo");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Purchase Credit Memo";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          PurchComments.SETRANGE("Document Type" , PurchComments."Document Type"::"Posted Credit Memo");
          PurchComments.SETRANGE("No." , "No.") ;
          if PurchComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := PurchComments.Comment;
            if PurchComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := PurchComments.Comment;
              if PurchComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := PurchComments.Comment;
                if PurchComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := PurchComments.Comment;
                  if PurchComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := PurchComments.Comment;
                end;
              end;
            end;
          end;
          Vendor.GET("Pay-to Vendor No.");

          if Language.GET(Vendor."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Pay-to Vendor No.";
          TmpDocumentHeader.Name := "Pay-to Name";
          TmpDocumentHeader."Name 2" := "Pay-to Name 2";
          TmpDocumentHeader.Address := "Pay-to Address";
          TmpDocumentHeader."Address 2" := "Pay-to Address 2";
          TmpDocumentHeader.City := "Pay-to City";
          TmpDocumentHeader."Post Code" := "Pay-to Post Code";
          TmpDocumentHeader.Phone := Vendor."Phone No.";
          TmpDocumentHeader.FAX := Vendor."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Vendor."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Vendor."Tax Office";
          TmpDocumentHeader.Profession := Vendor.Profession;
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Purchaser Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          PurchCrMemoLine.SETCURRENTKEY("Return Order No.");
          PurchCrMemoLine.SETRANGE("Document No.", "No.");
          if PurchCrMemoLine.FINDSET then begin
            repeat
              if ((PurchCrMemoLine.Type <> PurchCrMemoLine.Type::" ")
              or ((PurchCrMemoLine.Type = PurchCrMemoLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item) and (PurchCrMemoLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := PurchCrMemoLine."Document No.";
                TmpDocumentLine."Line No." :=   PurchCrMemoLine."Line No.";
                TmpDocumentLine.Type :=  PurchCrMemoLine.Type;
                TmpDocumentLine."No." := PurchCrMemoLine."No.";
                //DOC IMP-DB-06/06/16 -
                //TmpDocumentLine.Description :=  PurchCrMemoLine.Description;
                TmpDocumentLine.Description :=  PurchCrMemoLine.Description+' '+PurchCrMemoLine."Description 2";
                //DOC IMP-DB-06/06/16 +
                TmpDocumentLine."Unit Of Measure" :=PurchCrMemoLine."Unit of Measure";
                TmpDocumentLine.Quantity:= PurchCrMemoLine.Quantity ;
                TmpDocumentLine."Unit Price" := PurchCrMemoLine."Unit Cost";
                TmpDocumentLine.Amount := ROUND((PurchCrMemoLine.Quantity * PurchCrMemoLine."Unit Cost"),
                                          GLSetup."Amount Rounding Precision");
                TmpDocumentLine."Line Discount %" := PurchCrMemoLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := PurchCrMemoLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := PurchCrMemoLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := PurchCrMemoLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := PurchCrMemoLine.Amount;
                TmpDocumentLine."VAT %" := FORMAT(PurchCrMemoLine."VAT %");
                TmpDocumentLine."VAT Amount" := (PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount);
                TmpDocumentLine."Amount Inc. VAT" := PurchCrMemoLine."Amount Including VAT";
                //Sumarize amounts
                if PurchCrMemoLine.Type = PurchCrMemoLine.Type::"Charge (Item)" then begin
                  ChargeAmounts.Quantity := ChargeAmounts.Quantity + TmpDocumentLine.Quantity;
                  ChargeAmounts.Amount := ChargeAmounts.Amount + TmpDocumentLine.Amount;
                  ChargeAmounts."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  ChargeAmounts."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  ChargeAmounts."Line Amount" += TmpDocumentLine."Line Amount";
                  ChargeAmounts."Amount After Discount" := ChargeAmounts."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                  ChargeAmounts."VAT Amount" := ChargeAmounts."VAT Amount" + TmpDocumentLine."VAT Amount";
                  ChargeAmounts."Amount Inc. VAT" := ChargeAmounts."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end else begin
                  SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                  SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                  SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                  SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                  SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                  SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                  SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                  SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                end;
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
                if (PurchCrMemoHeader."Cancellation Type" = PurchCrMemoHeader."Cancellation Type"::" ") and
                   (PurchCrMemoHeader."Operation Type" = PurchCrMemoHeader."Operation Type"::Invoice) and
                   (PurchCrMemoLine."Return Order No." <> '') and
                   (PurchCrMemoLine."Return Order No." <> CurrRetOrderNo)
                then begin
                  CurrRetOrderNo := PurchCrMemoLine."Return Order No.";
                  RetShptHeader.RESET;
                  RetShptHeader.SETCURRENTKEY("Return Order No.");
                  RetShptHeader.SETRANGE("Return Order No.",CurrRetOrderNo);
                  if RetShptHeader.FINDFIRST then begin
                    if (STRLEN(TmpRelDocLine.Description + RetShptHeader."No." + ', ') >
                        MAXSTRLEN(TmpRelDocLine.Description)) or
                       (TmpRelDocLine.Description = '')
                    then begin
                      TmpRelDocLine.INIT;
                      TmpRelDocLine."Document No." := PurchCrMemoHeader."No.";
                      TmpRelDocLine."Line No." := PurchCrMemoLine."Line No.";
                      TmpRelDocLine.Description := RetShptHeader."No.";
                      TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                      TmpRelDocLine.INSERT;
                    end else begin
                      TmpRelDocLine.Description += ', ' + RetShptHeader."No.";
                      TmpRelDocLine.MODIFY;
                    end;
                  end;
                end;
              end;
            until PurchCrMemoLine.NEXT=0;

            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Purchases);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;

          end;

          if PurchCrMemoHeader."Cancellation Type" <> PurchCrMemoHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := PurchCrMemoHeader."No.";
            TmpRelDocLine."Line No." := 10000;
            TmpRelDocLine.Description := PurchCrMemoHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (PurchCrMemoHeader."Return Order No." <> '') and
               (PurchCrMemoHeader."Operation Type" = PurchCrMemoHeader."Operation Type"::Invoice)
            then begin
              RetShptHeader.RESET;
              RetShptHeader.SETCURRENTKEY("Return Order No.");
              RetShptHeader.SETRANGE("Return Order No.",PurchCrMemoHeader."Return Order No.");
              if RetShptHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + RetShptHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := PurchCrMemoHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := RetShptHeader."No." + ', ';
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += RetShptHeader."No." + ', ';
                  TmpRelDocLine.MODIFY;
                end;
              until RetShptHeader.NEXT=0;
            end;
          end;

          Vendor.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Vendor.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" +
                                             (SumAmount."Amount Inc. VAT" + ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";

          UpdateHeaderVatDetails(TmpDocumentHeader);
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"+";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Purch. Cr. Memo Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPurchReceipt(PurchRcptHeader : Record "Purch. Rcpt. Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        PurchRcptLine : Record "Purch. Rcpt. Line";
        Vendor : Record Vendor;
        PurchComments : Record "Purch. Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GlobalDocNo := PurchRcptHeader."No.";
        with PurchRcptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"P.Receipt");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Purchase Receipt";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          PurchComments.SETRANGE("Document Type" , PurchComments."Document Type"::Receipt);
          PurchComments.SETRANGE("No." , "No.") ;
          if PurchComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := PurchComments.Comment;
            if PurchComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := PurchComments.Comment;
              if PurchComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := PurchComments.Comment;
                if PurchComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := PurchComments.Comment;
                  if PurchComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := PurchComments.Comment;
                end;
              end;
            end;
          end;

          Vendor.GET("Buy-from Vendor No.");

          if Language.GET(Vendor."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Buy-from Vendor No.";
          TmpDocumentHeader.Name := "Buy-from Vendor Name";
          TmpDocumentHeader."Name 2" := "Buy-from Vendor Name 2";
          TmpDocumentHeader.Address := "Buy-from Address";
          TmpDocumentHeader."Address 2" := "Buy-from Address 2";
          TmpDocumentHeader.City := "Buy-from City";
          TmpDocumentHeader."Post Code" := "Buy-from Post Code";
          TmpDocumentHeader.Phone := Vendor."Phone No.";
          TmpDocumentHeader.FAX := Vendor."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Vendor."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Vendor."Tax Office";
          TmpDocumentHeader.Profession := Vendor.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Purchaser Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          PurchRcptLine.SETRANGE("Document No.", "No.");
          if PurchRcptLine.FINDSET then begin
            repeat
              if ((PurchRcptLine.Type <> PurchRcptLine.Type::" ")
              or ((PurchRcptLine.Type = PurchRcptLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((PurchRcptLine.Type = PurchRcptLine.Type::Item) and (PurchRcptLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := PurchRcptLine."Document No.";
                TmpDocumentLine."Line No." :=   PurchRcptLine."Line No.";
                TmpDocumentLine.Type :=  PurchRcptLine.Type;
                TmpDocumentLine."No." := PurchRcptLine."No.";
                //DOC IMP-DB-06/06/16 -
                //TmpDocumentLine.Description :=  PurchRcptLine.Description;
                TmpDocumentLine.Description :=  PurchRcptLine.Description+' '+PurchRcptLine."Description 2";
                //DOC IMP-DB-06/06/16 +
                TmpDocumentLine."Unit Of Measure" := PurchRcptLine."Unit of Measure";
                TmpDocumentLine.Quantity := PurchRcptLine.Quantity ;
                TmpDocumentHeader."Total Quantity"  += PurchRcptLine.Quantity;
                TmpDocumentLine.INSERT;
              end;
            until PurchRcptLine.NEXT=0;
          end;

          if PurchRcptHeader."Cancellation Type" <> PurchRcptHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := PurchRcptHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := PurchRcptHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;

          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Purch. Rcpt. Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPurchReturnShipment(ReturnShipmentHeader : Record "Return Shipment Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ReturnShipmentLine : Record "Return Shipment Line";
        Vendor : Record Vendor;
        PurchComments : Record "Purch. Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GlobalDocNo := ReturnShipmentHeader."No.";
        with ReturnShipmentHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"P.Ret.Shpt.");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Purchase Return Shipment";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          PurchComments.SETRANGE("Document Type" , PurchComments."Document Type"::"Posted Return Shipment");
          PurchComments.SETRANGE("No." , "No.") ;
          if PurchComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := PurchComments.Comment;
            if PurchComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := PurchComments.Comment;
              if PurchComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := PurchComments.Comment;
                if PurchComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := PurchComments.Comment;
                  if PurchComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := PurchComments.Comment;
                end;
              end;
            end;
          end;

          Vendor.GET("Buy-from Vendor No.");

          if Language.GET(Vendor."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";

          TmpDocumentHeader."No." := "Buy-from Vendor No.";
          TmpDocumentHeader.Name := "Buy-from Vendor Name";
          TmpDocumentHeader."Name 2" := "Buy-from Vendor Name 2";
          TmpDocumentHeader.Address := "Buy-from Address";
          TmpDocumentHeader."Address 2" := "Buy-from Address 2";
          TmpDocumentHeader.City := "Buy-from City";
          TmpDocumentHeader."Post Code" := "Buy-from Post Code";
          TmpDocumentHeader.Phone := Vendor."Phone No.";
          TmpDocumentHeader.FAX := Vendor."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Vendor."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Vendor."Tax Office";
          TmpDocumentHeader.Profession := Vendor.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;

          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Purchaser Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ShipmentMethod.GET("Shipment Method Code") then
            TmpDocumentHeader."Shipment Method" := ShipmentMethod.Description;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ReturnShipmentLine.SETRANGE("Document No.", "No.");
          if ReturnShipmentLine.FINDSET then begin
            repeat
              if ((ReturnShipmentLine.Type <> ReturnShipmentLine.Type::" ")
              or ((ReturnShipmentLine.Type = ReturnShipmentLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ReturnShipmentLine.Type = ReturnShipmentLine.Type::Item) and (ReturnShipmentLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ReturnShipmentLine."Document No.";
                TmpDocumentLine."Line No." :=   ReturnShipmentLine."Line No.";
                TmpDocumentLine.Type :=  ReturnShipmentLine.Type;
                TmpDocumentLine."No." := ReturnShipmentLine."No.";
                //DOC IMP-DB-06/06/16 -
                //TmpDocumentLine.Description :=  ReturnShipmentLine.Description;
                TmpDocumentLine.Description :=  ReturnShipmentLine.Description+' '+ReturnShipmentLine."Description 2";
                //DOC IMP-DB-06/06/16 +
                TmpDocumentLine."Unit Of Measure" := ReturnShipmentLine."Unit of Measure";
                TmpDocumentLine.Quantity := ReturnShipmentLine.Quantity ;
                TmpDocumentHeader."Total Quantity"  += ReturnShipmentLine.Quantity;
                TmpDocumentLine.INSERT;
              end;
            until ReturnShipmentLine.NEXT=0;
          end;

          if ReturnShipmentHeader."Cancellation Type" <> ReturnShipmentHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ReturnShipmentHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := ReturnShipmentHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;

          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Net Weight" := General.CalcReturnShipmentHeaderNetWeight(ReturnShipmentHeader); //DOC-IMP-DB-15/06/16
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Return Shipment Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromTransferOrder(TransferHeader : Record "Transfer Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        TransferLine : Record "Transfer Line";
        InventoryComments : Record "Inventory Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        with TransferHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::Inv1);
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."No. Series" :="No. Series";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Transfer Order";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          InventoryComments.SETRANGE("Document Type" , InventoryComments."Document Type"::"Transfer Order");
          InventoryComments.SETRANGE("No." , "No.") ;
          if InventoryComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := InventoryComments.Comment;
            if InventoryComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := InventoryComments.Comment;
              if InventoryComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := InventoryComments.Comment;
                if InventoryComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := InventoryComments.Comment;
                  if InventoryComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := InventoryComments.Comment;
                end;
              end;
            end;
          end;
          if ReasonCode.GET("Transfer Reason") then begin
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          end;
          if Location.GET("In-Transit Code") then
            TmpDocumentHeader."Location Address" := Location.Name;

          if Cancellation then begin
            TmpDocumentHeader."No." := "Transfer-to Code";
            TmpDocumentHeader.Name := "Transfer-to Name";
            TmpDocumentHeader."Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader.Address := "Transfer-to Address";
            TmpDocumentHeader."Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader.City := "Transfer-to City";
            TmpDocumentHeader."Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;

            TmpDocumentHeader."Ship-To Code" := "Transfer-from Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-from Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-from Address";
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-from City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end else begin
            TmpDocumentHeader."No." := "Transfer-from Code";
            TmpDocumentHeader.Name := "Transfer-from Name";
            TmpDocumentHeader."Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader.Address := "Transfer-from Address";
            TmpDocumentHeader."Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader.City := "Transfer-from City";
            TmpDocumentHeader."Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;

            TmpDocumentHeader."Ship-To Code" := "Transfer-to Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-to Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-to Address" ;
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-to City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end;
          TransferLine.SETRANGE("Document No.", "No.");
          TransferLine.SETRANGE("Derived From Line No.",0);
          if TransferLine.FINDSET then begin
            repeat
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := TransferLine."Document No.";
              TmpDocumentLine."Line No." :=   TransferLine."Line No.";
              TmpDocumentLine.Type := TmpDocumentLine.Type::Item;
              TmpDocumentLine."No." := TransferLine."Item No.";
              //DOC IMP-DB-06/06/16 -
              //TmpDocumentLine.Description :=  TransferLine.Description;
              TmpDocumentLine.Description :=  TransferLine.Description+' '+TransferLine."Description 2";
              //DOC IMP-DB-06/06/16 +
              TmpDocumentLine."Unit Of Measure" := TransferLine."Unit of Measure";
              TmpDocumentLine.Quantity := TransferLine.Quantity ;
              TmpDocumentHeader."Total Quantity"  += TransferLine.Quantity;
              TmpDocumentLine.INSERT;
            until TransferLine.NEXT=0;
          end;

          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Net Weight" := General.CalcTransferHeaderNetWeight(TransferHeader); //DOC-IMP-DB-15/06/16
          TmpDocumentHeader.INSERT;
        end;

        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromTransferShipment(TransferShptHeader : Record "Transfer Shipment Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        TransferShptLine : Record "Transfer Shipment Line";
        InventoryComments : Record "Inventory Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GlobalDocNo := TransferShptHeader."No.";
        with TransferShptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::Inv2);
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;

          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."No. Series" :="No. Series";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Transfer Shipment";
          TmpDocumentHeader."Transfer Order No." := "Transfer Order No.";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          InventoryComments.SETRANGE("Document Type" , InventoryComments."Document Type"::"Posted Transfer Shipment");
          InventoryComments.SETRANGE("No." , "No.") ;
          if InventoryComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := InventoryComments.Comment;
            if InventoryComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := InventoryComments.Comment;
              if InventoryComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := InventoryComments.Comment;
                if InventoryComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := InventoryComments.Comment;
                  if InventoryComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := InventoryComments.Comment;
                end;
              end;
            end;
          end;
          if ReasonCode.GET("Transfer Reason") then begin
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          end;
          if Location.GET("In-Transit Code") then
            TmpDocumentHeader."Location Address" := Location.Name;

          if Cancellation then begin
            TmpDocumentHeader."No." := "Transfer-to Code";
            TmpDocumentHeader.Name := "Transfer-to Name";
            TmpDocumentHeader."Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader.Address := "Transfer-to Address";
            TmpDocumentHeader."Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader.City := "Transfer-to City";
            TmpDocumentHeader."Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;

            TmpDocumentHeader."Ship-To Code" := "Transfer-from Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-from Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-from Address";
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-from City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end else begin
            TmpDocumentHeader."No." := "Transfer-from Code";
            TmpDocumentHeader.Name := "Transfer-from Name";
            TmpDocumentHeader."Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader.Address := "Transfer-from Address";
            TmpDocumentHeader."Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader.City := "Transfer-from City";
            TmpDocumentHeader."Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;

            TmpDocumentHeader."Ship-To Code" := "Transfer-to Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-to Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-to Address";
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-to City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end;


          TransferShptLine.SETRANGE("Document No.", "No.");
          if TransferShptLine.FINDSET then begin
            repeat
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := TransferShptLine."Document No.";
              TmpDocumentLine."Line No." := TransferShptLine."Line No.";
              TmpDocumentLine.Type := TmpDocumentLine.Type::Item;
              TmpDocumentLine."No." := TransferShptLine."Item No.";
              //DOC IMP-DB-06/06/16 -
              //TmpDocumentLine.Description :=  TransferShptLine.Description;
              TmpDocumentLine.Description :=  TransferShptLine.Description+' '+TransferShptLine."Description 2";
              //DOC IMP-DB-06/06/16 +
              TmpDocumentLine."Unit Of Measure" := TransferShptLine."Unit of Measure";
              TmpDocumentLine.Quantity := TransferShptLine.Quantity ;
              TmpDocumentHeader."Total Quantity"  += TransferShptLine.Quantity;
              TmpDocumentLine.INSERT;
            until TransferShptLine.NEXT=0;
          end;

          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader."Net Weight" := General.CalcTransferShipmentHeaderNetWeight(TransferShptHeader); //DOC-IMP-DB-15/06/16
          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Transfer Shipment Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromTransferReceipt(TransferRcptHeader : Record "Transfer Receipt Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        TransferRcptLine : Record "Transfer Receipt Line";
        InventoryComments : Record "Inventory Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GlobalDocNo := TransferRcptHeader."No.";
        with TransferRcptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::Inv3);
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;

          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."No. Series" :="No. Series";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Transfer Receipt";
          TmpDocumentHeader."Transfer Order No." := "Transfer Order No.";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          InventoryComments.SETRANGE("Document Type" , InventoryComments."Document Type"::"Posted Transfer Receipt");
          InventoryComments.SETRANGE("No." , "No.") ;
          if InventoryComments.FINDSET then begin
            TmpDocumentHeader."Comments 01" := InventoryComments.Comment;
            if InventoryComments.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := InventoryComments.Comment;
              if InventoryComments.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := InventoryComments.Comment;
                if InventoryComments.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := InventoryComments.Comment;
                  if InventoryComments.NEXT <> 0 then
                    TmpDocumentHeader."Comments 05" := InventoryComments.Comment;
                end;
              end;
            end;
          end;
          if ReasonCode.GET("Transfer Reason") then begin
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          end;
          if Location.GET("In-Transit Code") then
            TmpDocumentHeader."Location Address" := Location.Name;

          if Cancellation then begin
            TmpDocumentHeader."No." := "Transfer-to Code";
            TmpDocumentHeader.Name := "Transfer-to Name";
            TmpDocumentHeader."Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader.Address := "Transfer-to Address";
            TmpDocumentHeader."Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader.City := "Transfer-to City";
            TmpDocumentHeader."Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;

            TmpDocumentHeader."Ship-To Code" := "Transfer-from Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-from Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-from Address";
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-from City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end else begin
            TmpDocumentHeader."No." := "Transfer-from Code";
            TmpDocumentHeader.Name := "Transfer-from Name";
            TmpDocumentHeader."Name 2" := "Transfer-from Name 2";
            TmpDocumentHeader.Address := "Transfer-from Address";
            TmpDocumentHeader."Address 2" := "Transfer-from Address 2";
            TmpDocumentHeader.City := "Transfer-from City";
            TmpDocumentHeader."Post Code" := "Transfer-from Post Code";
            if Location.GET("Transfer-from Code") then begin
              TmpDocumentHeader.Phone := Location."Phone No.";
              TmpDocumentHeader.FAX := Location."Fax No.";
              TmpDocumentHeader.Profession := Location.Profession;
              TmpDocumentHeader."Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Tax Office" := Location."Tax Office";
            end;
            TmpDocumentHeader."Ship-To Code" := "Transfer-to Code";
            TmpDocumentHeader."Ship-To Name" := "Transfer-to Name";
            TmpDocumentHeader."Ship-To Name 2" := "Transfer-to Name 2";
            TmpDocumentHeader."Ship-To Address" := "Transfer-to Address";
            TmpDocumentHeader."Ship-To Address 2" := "Transfer-to Address 2";
            TmpDocumentHeader."Ship-To City" := "Transfer-to City";
            TmpDocumentHeader."Ship-To Post Code" := "Transfer-to Post Code";
            if Location.GET("Transfer-to Code") then begin
              TmpDocumentHeader."Ship-To Phone" := Location."Phone No.";
              TmpDocumentHeader."Ship-To FAX" := Location."Fax No.";
              TmpDocumentHeader."Ship-To Profession" := Location.Profession;
              TmpDocumentHeader."Ship-To Vat Registration No." := Location."VAT Registration No.";
              TmpDocumentHeader."Ship-To Tax Office" := Location."Tax Office";
            end;
          end;

          TransferRcptLine.SETRANGE("Document No.", "No.");
          if TransferRcptLine.FINDSET then begin
            repeat
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := TransferRcptLine."Document No.";
              TmpDocumentLine."Line No." :=   TransferRcptLine."Line No.";
              TmpDocumentLine.Type := TmpDocumentLine.Type::Item;
              TmpDocumentLine."No." := TransferRcptLine."Item No.";
              //DOC IMP-DB-06/06/16 -
              //TmpDocumentLine.Description :=  TransferRcptLine.Description;
              TmpDocumentLine.Description :=  TransferRcptLine.Description+' '+TransferRcptLine."Description 2";
              //DOC IMP-DB-06/06/16 +
              TmpDocumentLine."Unit Of Measure" := TransferRcptLine."Unit of Measure";
              TmpDocumentLine.Quantity := TransferRcptLine.Quantity ;
              TmpDocumentHeader."Total Quantity"  += TransferRcptLine.Quantity;
              TmpDocumentLine.INSERT;
            until TransferRcptLine.NEXT=0;
          end;


          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Transfer Receipt Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromPostedChequeTrans(PostedChequeTransHeader : Record "Posted Cheque Trans. Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary) : Boolean;
    var
        PostedChequeTransLine : Record "Posted Cheque Trans. Line";
        SumAmount : Record "Document Line" temporary;
        CPNPosition : Record "CPN Position";
        Cheque : Record Cheque;
        Customer : Record Customer;
        Vendor : Record Vendor;
        Bank : Record "Bank Account";
        Lawyer : Record "CPN Lawyer";
        GLAccount : Record "G/L Account";
        LineNo : Integer;
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CPNSetup.GET;

        with PostedChequeTransHeader do begin
          CPNPostingSetup.GET("Posting Group Code");
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Cheque Transaction";
          TmpDocumentHeader."No. Series Description" := CPNPostingSetup."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          TmpDocumentHeader."Comments 01" := "Posting Description";

          if CPNPosition.GET("Previous Position") then
            TmpDocumentHeader."Comments 02" := CPNPosition.Description;

          if CPNPosition.GET("Next Position") then begin
            TmpDocumentHeader."Comments 03" := CPNPosition.Description;

            TmpDocumentHeader."Comments 04" := "Next Acc. No.";

            case CPNPosition.Type of
              CPNPosition.Type::"GL Account" :
                begin
                  if GLAccount.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := GLAccount.Name;
                end;
              CPNPosition.Type::Bank :
                begin
                  if Bank.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Bank.Name;
                end;
              CPNPosition.Type::Vendor :
                begin
                  if Vendor.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Vendor.Name;
                end;
              CPNPosition.Type::Customer :
                begin
                  if Customer.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Customer.Name;
                end;
              CPNPosition.Type::Lawyer :
                begin
                  if Lawyer.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Lawyer.Name;
                  end;
            end;
          end;

          //IF CPNSetup."Printing Method" = CPNSetup."Printing Method"::"One by one" THEN
            PostedChequeTransLine.SETRANGE("Document No.", "No.");
          //ELSE
          //  PostedChequeTransLine.SETRANGE("Cheque Transaction No.","Cheque Transaction No.");

          if PostedChequeTransLine.FINDSET then begin
            repeat
              TmpDocumentLine.INIT;
              //IF CPNSetup."Printing Method" = CPNSetup."Printing Method"::"One by one" THEN
                TmpDocumentLine."Document No." := "No.";
              //ELSE
              //  TmpDocumentLine."Document No." := "Cheque Transaction No.";
              LineNo +=1;
              TmpDocumentLine."Line No." := LineNo;
              TmpDocumentLine.Amount := PostedChequeTransLine."Cheque Amount";

              if Cheque.GET(PostedChequeTransLine."No.") then begin
                TmpDocumentLine."CPN No." := Cheque."Cheque Number";
                TmpDocumentLine."Value Date" := Cheque."Value Date";
                if Bank.GET(Cheque."Bank and Branch Code") then
                  TmpDocumentLine."Bank Name" := Bank.Name;
              end;

              TmpDocumentLine."No." := PostedChequeTransLine."Previous Acc. No.";

              case PostedChequeTransLine."Previous Position Type" of
                PostedChequeTransLine."Previous Position Type"::"GL Account" :
                  begin
                    if GLAccount.GET(PostedChequeTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := GLAccount.Name;
                    end;
                PostedChequeTransLine."Previous Position Type"::Bank :
                  begin
                    if Bank.GET(PostedChequeTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Bank.Name;
                  end;
                PostedChequeTransLine."Previous Position Type"::Vendor :
                  begin
                    if Vendor.GET(PostedChequeTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Vendor.Name;
                  end;
                PostedChequeTransLine."Previous Position Type"::Customer :
                  begin
                    if Customer.GET(PostedChequeTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Customer.Name;
                  end;
                PostedChequeTransLine."Previous Position Type"::Lawyer :
                  begin
                    if Lawyer.GET(PostedChequeTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Lawyer.Name;
                  end;
              end;

              SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
              SumAmount.Quantity += 1;
              TmpDocumentLine.INSERT;

            until PostedChequeTransLine.NEXT=0;
          end;

          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Maximum Line Per Page" := CPNPostingSetup."Lines Per Page";
          TmpDocumentHeader.INSERT;

        end;

        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
    end;

    procedure CopyFromPostedPNTrans(PostedPNTransHeader : Record "Posted PN Trans. Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary) : Boolean;
    var
        PostedPNTransLine : Record "Posted PN Trans. Line";
        SumAmount : Record "Document Line" temporary;
        CPNPosition : Record "CPN Position";
        PN : Record "Promissory Note";
        Customer : Record Customer;
        Vendor : Record Vendor;
        Bank : Record "Bank Account";
        Lawyer : Record "CPN Lawyer";
        GLAccount : Record "G/L Account";
        LineNo : Integer;
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CPNSetup.GET;

        with PostedPNTransHeader do begin
          CPNPostingSetup.GET("Posting Group Code");
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"PN Transaction";
          TmpDocumentHeader."No. Series Description" := CPNPostingSetup."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          TmpDocumentHeader."Comments 01" := "Posting Description";

          if CPNPosition.GET("Previous Position") then
            TmpDocumentHeader."Comments 02" := CPNPosition.Description;

          if CPNPosition.GET("Next Position") then begin
            TmpDocumentHeader."Comments 03" := CPNPosition.Description;

            TmpDocumentHeader."Comments 04" := "Next Acc. No.";

            case CPNPosition.Type of
              CPNPosition.Type::"GL Account" :
                begin
                  if GLAccount.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := GLAccount.Name;
                end;
              CPNPosition.Type::Bank :
                begin
                  if Bank.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Bank.Name;
                end;
              CPNPosition.Type::Vendor :
                begin
                  if Vendor.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Vendor.Name;
                end;
              CPNPosition.Type::Customer :
                begin
                  if Customer.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Customer.Name;
                end;
              CPNPosition.Type::Lawyer :
                begin
                  if Lawyer.GET("Next Acc. No.") then
                    TmpDocumentHeader."Comments 05" := Lawyer.Name;
                  end;
            end;
          end;

          //IF CPNSetup."Printing Method" = CPNSetup."Printing Method"::"One by one" THEN
            PostedPNTransLine.SETRANGE("Document No.", "No.");
          //ELSE
          //  PostedPNTransLine.SETRANGE("PN Transaction No.","PN Transaction No.");

          if PostedPNTransLine.FINDSET then begin
            repeat
              TmpDocumentLine.INIT;
              //IF CPNSetup."Printing Method" = CPNSetup."Printing Method"::"One by one" THEN
              TmpDocumentLine."Document No." := "No.";
              //ELSE
              //  TmpDocumentLine."Document No." := "PN Transaction No.";
              LineNo +=1;
              TmpDocumentLine."Line No." := LineNo;
              TmpDocumentLine.Amount := PostedPNTransLine."PN Amount";

              if PN.GET(PostedPNTransLine."PN No.") then begin
                TmpDocumentLine."CPN No." := PN."PN Number";
                TmpDocumentLine."Value Date" := PN."Value Date";
                if Bank.GET(PN."Bank and Branch Code") then
                  TmpDocumentLine."Bank Name" := Bank.Name;
              end;

              TmpDocumentLine."No." := PostedPNTransLine."Previous Acc. No.";

              case PostedPNTransLine."Previous Position Type" of
                PostedPNTransLine."Previous Position Type"::"GL Account" :
                  begin
                    if GLAccount.GET(PostedPNTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := GLAccount.Name;
                    end;
                PostedPNTransLine."Previous Position Type"::Bank :
                  begin
                    if Bank.GET(PostedPNTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Bank.Name;
                  end;
                PostedPNTransLine."Previous Position Type"::Vendor :
                  begin
                    if Vendor.GET(PostedPNTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Vendor.Name;
                  end;
                PostedPNTransLine."Previous Position Type"::Customer :
                  begin
                    if Customer.GET(PostedPNTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Customer.Name;
                  end;
                PostedPNTransLine."Previous Position Type"::Lawyer :
                  begin
                    if Lawyer.GET(PostedPNTransLine."Previous Acc. No.") then
                      TmpDocumentLine.Description := Lawyer.Name;
                  end;
              end;

              SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
              SumAmount.Quantity += 1;
              TmpDocumentLine.INSERT;

            until PostedPNTransLine.NEXT=0;
          end;

          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Maximum Line Per Page" := CPNPostingSetup."Lines Per Page";
          TmpDocumentHeader.INSERT;

        end;

        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
    end;

    procedure "__Global Functions___"();
    begin
    end;

    procedure CalculateVATDetails(TmpDocumentLine : Record "Document Line" temporary);
    var
        Counter : Integer;
        Pos : Integer;
        IsTrue : Boolean;
        NetAmount : Decimal;
        VatAmount : Decimal;
    begin
        Pos := 0;

          for Counter := 1 to 5 do begin
            if VAT_Pct[Counter] = TmpDocumentLine."VAT %" then
              Pos := Counter;
          end;

          if Pos = 0 then begin
            for Counter := 1 to 5 do begin
              if (VAT_Pct[Counter] ='') and (not IsTrue) then begin
                VAT_Pct[Counter] :=TmpDocumentLine."VAT %";
                Pos := Counter;
                IsTrue:= true;
              end;
            end;
          end;
          if (VAT_Pct[Pos] = TmpDocumentLine."VAT %") then begin
             NetAmount:= VAT_Net_Amount[Pos];
             VatAmount:= VAT_Amount[Pos];
             NetAmount:= NetAmount + TmpDocumentLine."Amount After Discount";
             VatAmount:= VatAmount + TmpDocumentLine."VAT Amount";
             VAT_Net_Amount[Pos]:= NetAmount;
             VAT_Amount[Pos] := VatAmount;
          end;
    end;

    procedure InitVatDetails();
    var
        counter : Integer;
    begin
        for counter := 1 to 5 do begin
          VAT_Pct[counter] :='';
          VAT_Net_Amount[counter]:=0;
          VAT_Amount[counter]:=0;
        end;
    end;

    procedure UpdateHeaderVatDetails(var tmpDocumentHeader : Record "Document Header" temporary);
    begin
        tmpDocumentHeader."VAT Cat. 1" := VAT_Pct[1];
        tmpDocumentHeader."VAT Cat. 1 net Amount" := VAT_Net_Amount[1];
        tmpDocumentHeader."VAT Cat. 1  VAT Amount" := VAT_Amount[1];
        tmpDocumentHeader."VAT Cat. 2" := VAT_Pct[2];
        tmpDocumentHeader."VAT Cat. 2 net Amount" := VAT_Net_Amount[2];
        tmpDocumentHeader."VAT Cat. 2  VAT Amount" := VAT_Amount[2];
        tmpDocumentHeader."VAT Cat. 3" := VAT_Pct[3];
        tmpDocumentHeader."VAT Cat. 3 net Amount" := VAT_Net_Amount[3];
        tmpDocumentHeader."VAT Cat. 3  VAT Amount" := VAT_Amount[3];
        tmpDocumentHeader."VAT Cat. 4" := VAT_Pct[4];
        tmpDocumentHeader."VAT Cat. 4 net Amount" := VAT_Net_Amount[4];
        tmpDocumentHeader."VAT Cat. 4  VAT Amount" := VAT_Amount[4];
        tmpDocumentHeader."VAT Cat. 5" := VAT_Pct[5];
        tmpDocumentHeader."VAT Cat. 5 net Amount" := VAT_Net_Amount[5];
        tmpDocumentHeader."VAT Cat. 5  VAT Amount" := VAT_Amount[5];
        if (tmpDocumentHeader."VAT Cat. 1" = '0')
        and (tmpDocumentHeader."VAT Cat. 1 net Amount" = 0)
        and (tmpDocumentHeader."VAT Cat. 1  VAT Amount" = 0)
        then begin
          tmpDocumentHeader."VAT Cat. 1" := '';
        end;
        if (tmpDocumentHeader."VAT Cat. 2" = '0')
        and (tmpDocumentHeader."VAT Cat. 2 net Amount" = 0)
        and (tmpDocumentHeader."VAT Cat. 2  VAT Amount" = 0)
        then begin
          tmpDocumentHeader."VAT Cat. 2" := '';
        end;
        if (tmpDocumentHeader."VAT Cat. 3" = '0')
        and (tmpDocumentHeader."VAT Cat. 3 net Amount" = 0)
        and (tmpDocumentHeader."VAT Cat. 3  VAT Amount" = 0)
        then begin
          tmpDocumentHeader."VAT Cat. 3" := '';
        end;
        if (tmpDocumentHeader."VAT Cat. 4" = '0')
        and (tmpDocumentHeader."VAT Cat. 4 net Amount" = 0)
        and (tmpDocumentHeader."VAT Cat. 4  VAT Amount" = 0)
        then begin
          tmpDocumentHeader."VAT Cat. 4" := '';
        end;
        if (tmpDocumentHeader."VAT Cat. 5" = '0')
        and (tmpDocumentHeader."VAT Cat. 5 net Amount" = 0)
        and (tmpDocumentHeader."VAT Cat. 5  VAT Amount" = 0)
        then begin
          tmpDocumentHeader."VAT Cat. 5" := '';
        end;
    end;

    procedure FormatPages(var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;var TmpRelDocLine : Record "Document Line" temporary);
    var
        FormatLines : Integer;
        RelatedDescr : Text;
        TotalFormatLines : Integer;
        Amount : Decimal;
        VatAmount : Decimal;
        SumDocumentLine : Record "Document Line" temporary;
        RcText01 : TextConst ELL='Σε Μεταφορά',ENU='To Next Page';
        RcText02 : TextConst ELL='Από Μεταφορά',ENU='From Prev Page';
        NumberOfLines : Integer;
        CurrentNumberOfLines : Integer;
        MaxLinesPerPage : Integer;
        RelatedLineNo : Integer;
        GRText03 : TextConst ELL='Σχετικά Παραστατικά :',ENU='Related Documets :';
        NumberOfLoops : Integer;
        NumberOfPages : Integer;
        NumberOfBlankLines : Integer;
        i : Integer;
        RelatedCntr : Integer;
    begin
        TmpDocumentLine.SETRANGE("Document No." ,TmpDocumentHeader."Document No.");
        NumberOfLines := TmpDocumentLine.COUNT;
        MaxLinesPerPage :=TmpDocumentHeader."Maximum Line Per Page";
        if (NumberOfLines > MaxLinesPerPage) and (TmpDocumentHeader."Document Amount" <> 0) then begin
          CurrentNumberOfLines := 0;
          FormatLines := 0;
          TotalFormatLines :=0;
          if TmpDocumentLine.FINDSET then begin
            repeat
              CurrentNumberOfLines += 1;
              FormatLines :=FormatLines +1 ;
              TotalFormatLines := TotalFormatLines +1;
              Amount := Amount + TmpDocumentLine."Amount After Discount";
              VatAmount:=VatAmount + TmpDocumentLine."VAT Amount";

              if (FormatLines +1 = MaxLinesPerPage) and (CurrentNumberOfLines < NumberOfLines) then begin
                //Insert sum Line
                SumDocumentLine.INIT;
                SumDocumentLine."Document No." := TmpDocumentLine."Document No." ;
                SumDocumentLine."Line No." :=TmpDocumentLine."Line No."+1;
                SumDocumentLine.Type := SumDocumentLine.Type::" ";
                SumDocumentLine.Description := RcText01;
                SumDocumentLine."Amount After Discount" := Amount;
                SumDocumentLine."Line Amount" := Amount;
                SumDocumentLine."VAT Amount" :=VatAmount ;
                SumDocumentLine.INSERT;

                SumDocumentLine.INIT;
                SumDocumentLine."Document No." := TmpDocumentLine."Document No." ;
                SumDocumentLine."Line No." :=TmpDocumentLine."Line No."+2;
                SumDocumentLine.Type := SumDocumentLine.Type::" ";
                SumDocumentLine.Description := RcText02;
                SumDocumentLine."Amount After Discount" := Amount;
                SumDocumentLine."Line Amount" := Amount;
                SumDocumentLine."VAT Amount" :=VatAmount ;
                SumDocumentLine.INSERT;
                FormatLines := 1;

                if not ReportSelection."Progressive Transfer Totals" then begin
                  Amount :=0;
                  VatAmount :=0;
                end;
              end;
            until TmpDocumentLine.NEXT =0;
          end;
        end;

        if SumDocumentLine.FINDSET then begin
          repeat
            TmpDocumentLine.INIT;
            TmpDocumentLine:= SumDocumentLine;
            if TmpDocumentLine.INSERT then ;
          until SumDocumentLine.NEXT=0;
        end;

        if (not TmpRelDocLine.ISEMPTY) and (not TmpDocumentLine.ISEMPTY) then begin
          RelatedCntr := 0;
          TmpRelDocLine.FINDFIRST;
          if (STRLEN(GRText03) + STRLEN(TmpRelDocLine.Description) > MAXSTRLEN(TmpRelDocLine.Description)) then
            RelatedCntr := 1;
          NumberOfLines := TmpDocumentLine.COUNT + TmpRelDocLine.COUNT;
          NumberOfLoops :=  (NumberOfLines div MaxLinesPerPage) * MaxLinesPerPage +
                            (NumberOfLines mod MaxLinesPerPage) ;
          if (NumberOfLines mod MaxLinesPerPage) <>0 then
            NumberOfLoops := NumberOfLoops +(MaxLinesPerPage - NumberOfLines mod MaxLinesPerPage);
          NumberOfPages := NumberOfLoops div MaxLinesPerPage;
          NumberOfBlankLines := (NumberOfPages * MaxLinesPerPage) - (NumberOfLines + RelatedCntr);

          TmpDocumentLine.FINDLAST;
          for i := 1 to NumberOfBlankLines do begin
            TmpDocumentLine.INIT;
            TmpDocumentLine."Line No." += 1;
            TmpDocumentLine.INSERT;
          end;

          RelatedLineNo := TmpDocumentLine."Line No." + 1;
          TmpRelDocLine.RESET;
          if TmpRelDocLine.FINDSET then begin
            CLEAR(RelatedDescr);
            if (STRLEN(GRText03) + STRLEN(TmpRelDocLine.Description) > MAXSTRLEN(TmpRelDocLine.Description))
            then begin
              TmpDocumentLine.INIT;
              TmpDocumentLine."Document No." := TmpRelDocLine."Document No.";
              TmpDocumentLine."Line No." := RelatedLineNo;
              TmpDocumentLine.Description := GRText03;
              TmpDocumentLine.Type := TmpDocumentLine.Type::"Related Doc.";
              TmpDocumentLine."First Related Doc. Line" := true;
              TmpDocumentLine.INSERT;
              RelatedLineNo += 1;
            end else
              RelatedDescr := GRText03 + TmpRelDocLine.Description;
            repeat
              TmpDocumentLine.INIT;
              TmpDocumentLine := TmpRelDocLine;
              TmpDocumentLine."Line No." := RelatedLineNo;
              if RelatedDescr <> '' then begin
                TmpDocumentLine.Description := RelatedDescr;
                TmpDocumentLine."First Related Doc. Line" := true;
                CLEAR(RelatedDescr);
              end;
              TmpDocumentLine.INSERT;
              RelatedLineNo += 1;
            until TmpRelDocLine.NEXT = 0;
            TmpDocumentLine."Last Related Doc. Line" := true;
            TmpDocumentLine.MODIFY;
          end;
        end;
    end;

    procedure CopyFromServiceHeader(ServiceHeader : Record "Service Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ServiceLine : Record "Service Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        ServiceCommentLine : Record "Service Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        with ServiceHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"S.Order");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then begin
              exit(false);
            end;
          end;
          TmpDocumentHeader."Document No." := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Service Order";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then begin
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          end;
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          ServiceCommentLine.RESET;
          ServiceCommentLine.SETRANGE("Table Name",ServiceCommentLine."Table Name"::"Service Header");
          ServiceCommentLine.SETRANGE("No.","No.") ;
          if ServiceCommentLine.FINDSET then begin
            TmpDocumentHeader."Comments 01" := ServiceCommentLine.Comment;
            if ServiceCommentLine.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := ServiceCommentLine.Comment;
              if ServiceCommentLine.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := ServiceCommentLine.Comment;
                if ServiceCommentLine.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := ServiceCommentLine.Comment;
                  if ServiceCommentLine.NEXT <> 0 then begin
                    TmpDocumentHeader."Comments 05" := ServiceCommentLine.Comment;
                  end;
                end;
              end;
            end;
          end;
          Customer.GET("Customer No.");
          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          TmpDocumentHeader."No." := "Customer No.";
          TmpDocumentHeader.Name := Name;
          TmpDocumentHeader."Name 2" := "Name 2";
          TmpDocumentHeader.Address := Address;
          TmpDocumentHeader."Address 2" := "Address 2";
          TmpDocumentHeader.City := City;
          TmpDocumentHeader."Post Code" := "Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ServiceLine.SETRANGE("Document Type",ServiceLine."Document Type"::Order);
          ServiceLine.SETRANGE("Document No.","No.");
          if ServiceLine.FINDSET then begin
            repeat
              if ((ServiceLine.Type <> ServiceLine.Type::" ")
              or ((ServiceLine.Type = ServiceLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ServiceLine.Type = ServiceLine.Type::Item) and (ServiceLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ServiceLine."Document No.";
                TmpDocumentLine."Line No." := ServiceLine."Line No.";
                TmpDocumentLine.Type := ServiceLine.Type;
                TmpDocumentLine."No." := ServiceLine."No.";
                TmpDocumentLine.Description :=  ServiceLine.Description;
                TmpDocumentLine."Unit Of Measure" := ServiceLine."Unit of Measure";
                TmpDocumentLine.Quantity := ServiceLine.Quantity ;
                TmpDocumentLine."Unit Price" := ServiceLine."Unit Price";
                TmpDocumentLine.Amount := ROUND((ServiceLine.Quantity * ServiceLine."Unit Price"),GLSetup."Amount Rounding Precision");
                TmpDocumentLine."Line Discount %" := ServiceLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := ServiceLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := ServiceLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := ServiceLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := ServiceLine.Amount;
                TmpDocumentLine."VAT %" := FORMAT(ServiceLine."VAT %");
                TmpDocumentLine."VAT Amount" := (ServiceLine."Outstanding Amount" - ServiceLine."Line Amount");
                TmpDocumentLine."Amount Inc. VAT" := ServiceLine."Outstanding Amount";
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              end;
            until ServiceLine.NEXT=0;
          end;
          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
            (SumAmount."Amount Inc. VAT" + ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          UpdateHeaderVatDetails(TmpDocumentHeader);
          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Service Item Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader,TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromServiceInvoice(ServiceInvoiceHeader : Record "Service Invoice Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ServiceInvoiceLine : Record "Service Invoice Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        ServiceCommentLine : Record "Service Comment Line";
        CurrShipmentNo : Code[20];
        ServiceShipmentHeader : Record "Service Shipment Header";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        with ServiceInvoiceHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"SM.Invoice");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          GlobalDocNo := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Service Invoice";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          ServiceCommentLine.RESET;
          ServiceCommentLine.SETRANGE("Table Name",ServiceCommentLine."Table Name"::"Service Invoice Header");
          ServiceCommentLine.SETRANGE("No.","No.") ;
          if ServiceCommentLine.FINDSET then begin
            TmpDocumentHeader."Comments 01" := ServiceCommentLine.Comment;
            if ServiceCommentLine.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := ServiceCommentLine.Comment;
              if ServiceCommentLine.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := ServiceCommentLine.Comment;
                if ServiceCommentLine.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := ServiceCommentLine.Comment;
                  if ServiceCommentLine.NEXT <> 0 then begin
                    TmpDocumentHeader."Comments 05" := ServiceCommentLine.Comment;
                  end;
                end;
              end;
            end;
          end;
          Customer.GET("Bill-to Customer No.");
          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          TmpDocumentHeader."No." := "Bill-to Customer No.";
          TmpDocumentHeader.Name := "Bill-to Name";
          TmpDocumentHeader."Name 2" := "Bill-to Name 2";
          TmpDocumentHeader.Address := "Bill-to Address";
          TmpDocumentHeader."Address 2" := "Bill-to Address 2";
          TmpDocumentHeader.City := "Bill-to City";
          TmpDocumentHeader."Post Code" := "Bill-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Bill-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ServiceInvoiceLine.RESET;
          ServiceInvoiceLine.SETCURRENTKEY("Shipment No.","Shipment Line No.");
          ServiceInvoiceLine.SETRANGE("Document No.", "No.");
          if ServiceInvoiceLine.FINDSET then begin
            repeat
              if ((ServiceInvoiceLine.Type <> ServiceInvoiceLine.Type::" ")
              or ((ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::Item) and (ServiceInvoiceLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ServiceInvoiceLine."Document No.";
                TmpDocumentLine."Line No." :=   ServiceInvoiceLine."Line No.";
                TmpDocumentLine.Type :=  ServiceInvoiceLine.Type;
                TmpDocumentLine."No." := ServiceInvoiceLine."No.";
                TmpDocumentLine.Description :=  ServiceInvoiceLine.Description;
                TmpDocumentLine."Unit Of Measure" := ServiceInvoiceLine."Unit of Measure";
                TmpDocumentLine.Quantity:= ServiceInvoiceLine.Quantity ;
                TmpDocumentLine."Unit Price" := ServiceInvoiceLine."Unit Price";
                TmpDocumentLine.Amount := ROUND((ServiceInvoiceLine.Quantity * ServiceInvoiceLine."Unit Price"),
                  GLSetup."Amount Rounding Precision");
                TmpDocumentLine."Line Discount %" := ServiceInvoiceLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := ServiceInvoiceLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := ServiceInvoiceLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := ServiceInvoiceLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := ServiceInvoiceLine.Amount;
                TmpDocumentLine."VAT %" := FORMAT(ServiceInvoiceLine."VAT %");
                TmpDocumentLine."VAT Amount" := (ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount);
                TmpDocumentLine."Amount Inc. VAT" := ServiceInvoiceLine."Amount Including VAT";
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              end;
              if (ServiceInvoiceHeader."Cancellation Type" = ServiceInvoiceHeader."Cancellation Type"::" ") and
                 (ServiceInvoiceHeader."Operation Type" = ServiceInvoiceHeader."Operation Type"::Invoice) and
                 (ServiceInvoiceLine."Shipment No." <> '') and
                 (ServiceInvoiceLine."Shipment No." <> CurrShipmentNo)
              then begin
                CurrShipmentNo := ServiceInvoiceLine."Shipment No.";
                if (STRLEN(TmpRelDocLine.Description + ServiceInvoiceLine."Shipment No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := ServiceInvoiceHeader."No.";
                  TmpRelDocLine."Line No." := ServiceInvoiceLine."Line No.";
                  TmpRelDocLine.Description := ServiceInvoiceLine."Shipment No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + ServiceInvoiceLine."Shipment No.";
                  TmpRelDocLine.MODIFY;
                end;
              end;
            until ServiceInvoiceLine.NEXT=0;
            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Sales);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;
          end;
          if ServiceInvoiceHeader."Cancellation Type" <> ServiceInvoiceHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ServiceInvoiceHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := ServiceInvoiceHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (ServiceInvoiceHeader."Order No." <> '') and
               (ServiceInvoiceHeader."Operation Type" = ServiceInvoiceHeader."Operation Type"::Invoice)
            then begin
              ServiceShipmentHeader.RESET;
              ServiceShipmentHeader.SETCURRENTKEY("Order No.");
              ServiceShipmentHeader.SETRANGE("Order No.",ServiceInvoiceHeader."Order No.");
              if ServiceShipmentHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + ServiceShipmentHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := ServiceInvoiceHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := ServiceShipmentHeader."No." + ', ';
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ServiceShipmentHeader."No." + ', ';
                  TmpRelDocLine.MODIFY;
                end;
              until ServiceShipmentHeader.NEXT=0;
            end;
          end;
          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT"+ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          UpdateHeaderVatDetails(TmpDocumentHeader);

          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"+";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Service Invoice Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromServiceCreditMemo(ServiceCrMemoHeader : Record "Service Cr.Memo Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ServiceCrMemoLine : Record "Service Cr.Memo Line";
        SumAmount : Record "Document Line" temporary;
        ChargeAmounts : Record "Document Line" temporary;
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        ServiceCommentLine : Record "Service Comment Line";
        CurrRetReceiptNo : Code[20];
        ServiceReturnReceiptHeader : Record "Service Return Receipt Header";
        TmpRelDocLine : Record "Document Line" temporary;
        BailmentAmounts : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        GLSetup.GET;
        InitVatDetails;
        with ServiceCrMemoHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"SM.Credit Memo");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then begin
              exit(false);
            end;
          end;
          TmpDocumentHeader."Document No." := "No.";
          GlobalDocNo := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Service Credit Memo";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          ServiceCommentLine.RESET;
          ServiceCommentLine.SETRANGE("Table Name",ServiceCommentLine."Table Name"::"Service Cr.Memo Header");
          ServiceCommentLine.SETRANGE("No.","No.") ;
          if ServiceCommentLine.FINDSET then begin
            TmpDocumentHeader."Comments 01" := ServiceCommentLine.Comment;
            if ServiceCommentLine.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := ServiceCommentLine.Comment;
              if ServiceCommentLine.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := ServiceCommentLine.Comment;
                if ServiceCommentLine.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := ServiceCommentLine.Comment;
                  if ServiceCommentLine.NEXT <> 0 then begin
                    TmpDocumentHeader."Comments 05" := ServiceCommentLine.Comment;
                  end;
                end;
              end;
            end;
          end;
          Customer.GET("Bill-to Customer No.");
          if Language.GET(Customer."Language Code") then begin
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          end;
          TmpDocumentHeader."No." := "Bill-to Customer No.";
          TmpDocumentHeader.Name := "Bill-to Name";
          TmpDocumentHeader."Name 2" := "Bill-to Name 2";
          TmpDocumentHeader.Address := "Bill-to Address";
          TmpDocumentHeader."Address 2" := "Bill-to Address 2";
          TmpDocumentHeader.City := "Bill-to City";
          TmpDocumentHeader."Post Code" := "Bill-to Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Bill-to Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          TmpDocumentHeader."Location Address" := Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ServiceCrMemoLine.SETCURRENTKEY("Return Order No.","Ret. Order Line No.");
          ServiceCrMemoLine.SETRANGE("Document No.","No.");
          if ServiceCrMemoLine.FINDSET then begin
            repeat
              if ((ServiceCrMemoLine.Type <> ServiceCrMemoLine.Type::" ")
              or ((ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::Item) and (ServiceCrMemoLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ServiceCrMemoLine."Document No.";
                TmpDocumentLine."Line No." :=   ServiceCrMemoLine."Line No.";
                TmpDocumentLine.Type :=  ServiceCrMemoLine.Type;
                TmpDocumentLine."No." := ServiceCrMemoLine."No.";
                TmpDocumentLine.Description :=  ServiceCrMemoLine.Description;
                TmpDocumentLine."Unit Of Measure" := ServiceCrMemoLine."Unit of Measure";
                TmpDocumentLine.Quantity:= ServiceCrMemoLine.Quantity;
                TmpDocumentLine."Unit Price" := ServiceCrMemoLine."Unit Price";
                TmpDocumentLine.Amount := ROUND((ServiceCrMemoLine.Quantity * ServiceCrMemoLine."Unit Price"),
                  GLSetup."Amount Rounding Precision");
                TmpDocumentLine."Line Discount %" := ServiceCrMemoLine."Line Discount %";
                TmpDocumentLine."Line Discount Amount" := ServiceCrMemoLine."Line Discount Amount";
                TmpDocumentLine."Line Inv. Discount Amount" := ServiceCrMemoLine."Inv. Discount Amount";
                TmpDocumentLine."Line Amount" := ServiceCrMemoLine."Line Amount";
                TmpDocumentLine."Amount After Discount" := ServiceCrMemoLine.Amount;
                TmpDocumentLine."VAT %" := FORMAT(ServiceCrMemoLine."VAT %");
                TmpDocumentLine."VAT Amount" := (ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount);
                TmpDocumentLine."Amount Inc. VAT" := ServiceCrMemoLine."Amount Including VAT";
                SumAmount.Quantity := SumAmount.Quantity + TmpDocumentLine.Quantity;
                SumAmount.Amount := SumAmount.Amount + TmpDocumentLine.Amount;
                SumAmount."Line Discount Amount" += TmpDocumentLine."Line Discount Amount";
                SumAmount."Line Inv. Discount Amount" += TmpDocumentLine."Line Inv. Discount Amount";
                SumAmount."Line Amount" += TmpDocumentLine."Line Amount";
                SumAmount."Amount After Discount" := SumAmount."Amount After Discount" + TmpDocumentLine."Amount After Discount";
                SumAmount."VAT Amount" := SumAmount."VAT Amount" + TmpDocumentLine."VAT Amount";
                SumAmount."Amount Inc. VAT" := SumAmount."Amount Inc. VAT" + TmpDocumentLine."Amount Inc. VAT";
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              end;
              if (ServiceCrMemoHeader."Cancellation Type" = ServiceCrMemoHeader."Cancellation Type"::" ") and
                 (ServiceCrMemoHeader."Operation Type" = ServiceCrMemoHeader."Operation Type"::Invoice) and
                 (ServiceCrMemoLine."Return Order No." <> '') and
                 (ServiceCrMemoLine."Return Order No." <> CurrRetReceiptNo)
              then begin
                CurrRetReceiptNo := ServiceCrMemoLine."Return Order No.";
                if (STRLEN(TmpRelDocLine.Description + ServiceCrMemoLine."Return Order No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := ServiceCrMemoHeader."No.";
                  TmpRelDocLine."Line No." := ServiceCrMemoLine."Line No.";
                  TmpRelDocLine.Description := ServiceCrMemoLine."Return Order No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + ServiceCrMemoLine."Return Order No.";
                  TmpRelDocLine.MODIFY;
                end;
              end;
            until ServiceCrMemoLine.NEXT=0;
            TaxEntry.RESET;
            TaxEntry.SETRANGE("Posting Date","Posting Date");
            TaxEntry.SETRANGE(Area,TaxEntry.Area::Sales);
            TaxEntry.SETRANGE("Document No.","No.");
            if TaxEntry.FINDSET then begin
              TmpDocumentLine.FINDLAST;
              TmpDocumentLine.INIT;
              TmpDocumentLine."Line No." += 10000;
              TmpDocumentLine.Description := GRText001;
              TmpDocumentLine.INSERT;
              repeat
                TmpDocumentLine.INIT;
                TmpDocumentLine."Line No." += 10000;
                TmpDocumentLine.Description := TaxEntry."Printing Description";
                TmpDocumentLine.Amount := ABS(TaxEntry.Amount);
                TmpDocumentLine."VAT %" := FORMAT(TaxEntry."VAT %");
                TmpDocumentLine."VAT Amount" := ABS(TaxEntry."VAT Amount");
                TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount;
                SumAmount."Amount Inc. VAT" += ABS(TaxEntry."Amount Including VAT");
                TmpDocumentHeader."Document Tax Amount" += ABS(TaxEntry.Amount);
                TmpDocumentHeader."Document Tax VAT Amount" += ABS(TaxEntry."VAT Amount");
                TmpDocumentLine.INSERT;
                CalculateVATDetails(TmpDocumentLine);
              until TaxEntry.NEXT=0;
            end;
          end;
          if ServiceCrMemoHeader."Cancellation Type" <> ServiceCrMemoHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ServiceCrMemoHeader."No.";
            TmpRelDocLine."Line No." := 10000;
            TmpRelDocLine.Description := ServiceCrMemoHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end else begin
            if (ServiceCrMemoHeader."Return Order No." <> '') and
               (ServiceCrMemoHeader."Operation Type" = ServiceCrMemoHeader."Operation Type"::Invoice)
            then begin
              ServiceReturnReceiptHeader.RESET;
              ServiceReturnReceiptHeader.SETRANGE("No.",ServiceCrMemoHeader."Return Order No.");
              if ServiceReturnReceiptHeader.FINDSET then repeat
                if (STRLEN(TmpRelDocLine.Description + ServiceReturnReceiptHeader."No." + ', ') >
                    MAXSTRLEN(TmpRelDocLine.Description)) or
                   (TmpRelDocLine.Description = '')
                then begin
                  TmpRelDocLine.INIT;
                  TmpRelDocLine."Document No." := ServiceCrMemoHeader."No.";
                  TmpRelDocLine."Line No." += 10000;
                  TmpRelDocLine.Description := ServiceReturnReceiptHeader."No.";
                  TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
                  TmpRelDocLine.INSERT;
                end else begin
                  TmpRelDocLine.Description += ', ' + ServiceReturnReceiptHeader."No.";
                  TmpRelDocLine.MODIFY;
                end;
              until ServiceReturnReceiptHeader.NEXT=0;
            end;
          end;
          Customer.CALCFIELDS(Balance);
          TmpDocumentHeader."New Balance" := Customer.Balance;
          TmpDocumentHeader."Old Balance" := TmpDocumentHeader."New Balance" -
                                             (SumAmount."Amount Inc. VAT"+ChargeAmounts."Amount Inc. VAT");
          TmpDocumentHeader."Document Amount" := SumAmount.Amount;
          TmpDocumentHeader."Lines Discount Amount" := SumAmount."Line Discount Amount";
          TmpDocumentHeader."Invoice Discount Amount" := SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Discount Amount" := SumAmount."Line Discount Amount" + SumAmount."Line Inv. Discount Amount";
          TmpDocumentHeader."Document Amount After Discount" := SumAmount."Amount After Discount";
          TmpDocumentHeader."Document VAT Amount" := SumAmount."VAT Amount";
          TmpDocumentHeader."Document Charges Amount" := ChargeAmounts."Amount After Discount";
          TmpDocumentHeader."Document Charges VAT" := ChargeAmounts."VAT Amount";
          TmpDocumentHeader."Document Amount Inc. VAT" := SumAmount."Amount Inc. VAT" +ChargeAmounts."Amount Inc. VAT";
          TmpDocumentHeader."Total Quantity" := SumAmount.Quantity;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          UpdateHeaderVatDetails(TmpDocumentHeader);

          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"-";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Service Cr.Memo Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader,TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromServiceShipment(ServiceShipmentHeader : Record "Service Shipment Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ServiceShipmentLine : Record "Service Shipment Line";
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        ServiceCommentLine : Record "Service Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        with ServiceShipmentHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"SM.Shipment");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then
              exit(false);
          end;
          TmpDocumentHeader."Document No." := "No.";
          GlobalDocNo := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Service Shipment";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          ServiceCommentLine.RESET;
          ServiceCommentLine.SETRANGE("Table Name",ServiceCommentLine."Table Name"::"Service Shipment Header");
          ServiceCommentLine.SETRANGE("No.","No.");
          if ServiceCommentLine.FINDSET then begin
            TmpDocumentHeader."Comments 01" := ServiceCommentLine.Comment;
            if ServiceCommentLine.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := ServiceCommentLine.Comment;
              if ServiceCommentLine.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := ServiceCommentLine.Comment;
                if ServiceCommentLine.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := ServiceCommentLine.Comment;
                  if ServiceCommentLine.NEXT <> 0 then begin
                    TmpDocumentHeader."Comments 05" := ServiceCommentLine.Comment;
                  end;
                end;
              end;
            end;
          end;
          Customer.GET("Customer No.");
          if Language.GET(Customer."Language Code") then
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          TmpDocumentHeader."No." := "Customer No.";
          TmpDocumentHeader.Name := Name;
          TmpDocumentHeader."Name 2" := "Name 2";
          TmpDocumentHeader.Address := Address;
          TmpDocumentHeader."Address 2" := "Address 2";
          TmpDocumentHeader.City := City;
          TmpDocumentHeader."Post Code" := "Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          if Location.GET("Location Code") then
            TmpDocumentHeader."Location Address" := Location.Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ServiceShipmentLine.SETRANGE("Document No.","No.");
          if ServiceShipmentLine.FINDSET then begin
            repeat
              if ((ServiceShipmentLine.Type <> ServiceShipmentLine.Type::" ")
              or ((ServiceShipmentLine.Type = ServiceShipmentLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ServiceShipmentLine.Type = ServiceShipmentLine.Type::Item)
              and (ServiceShipmentLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ServiceShipmentLine."Document No.";
                TmpDocumentLine."Line No." :=   ServiceShipmentLine."Line No.";
                TmpDocumentLine.Type :=  ServiceShipmentLine.Type;
                TmpDocumentLine."No." := ServiceShipmentLine."No.";
                TmpDocumentLine.Description := ServiceShipmentLine.Description;
                TmpDocumentLine."Unit Of Measure" := ServiceShipmentLine."Unit of Measure";
                TmpDocumentLine.Quantity := ServiceShipmentLine.Quantity ;
                TmpDocumentHeader."Total Quantity"  += ServiceShipmentLine.Quantity;
                TmpDocumentLine.INSERT;
              end;
            until ServiceShipmentLine.NEXT=0;
          end;
          if ServiceShipmentHeader."Cancellation Type" <> ServiceShipmentHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ServiceShipmentHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := ServiceShipmentHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";
          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Service Shipment Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure CopyFromServiceReturnReceipt(ServiceReturnReceiptHeader : Record "Service Return Receipt Header";var TmpDocumentHeader : Record "Document Header" temporary;var TmpDocumentLine : Record "Document Line" temporary;ReportID : Integer) : Boolean;
    var
        ServiceReturnReceiptLine : Record "Service Return Receipt Line";
        Customer : Record Customer;
        ShipToAddress : Record "Ship-to Address";
        ServiceCommentLine : Record "Service Comment Line";
        TmpRelDocLine : Record "Document Line" temporary;
    begin
        CLEAR(TmpDocumentHeader);
        CLEAR(TmpDocumentLine);
        with ServiceReturnReceiptHeader do begin
          ReportSelection.SETRANGE(Usage, ReportSelection.Usage::"SM.Ret.Rcpt.");
          ReportSelection.SETRANGE("Report ID", ReportID);
          ReportSelection.SETRANGE(ReportSelection."No. Series" ,"No. Series");
          if not ReportSelection.FINDSET then begin
            ReportSelection.SETRANGE(ReportSelection."No. Series");
            if not ReportSelection.FINDSET then begin
              exit(false);
            end;
          end;
          TmpDocumentHeader."Document No." := "No.";
          GlobalDocNo := "No.";
          TmpDocumentHeader."Document Type" := TmpDocumentHeader."Document Type"::"Service Return Receipt";
          TmpDocumentHeader."No. Series" :="No. Series";
          if NoSeries.GET("No. Series") then begin
            TmpDocumentHeader."No. Series Description" := NoSeries."Printing Description";
          end;
          TmpDocumentHeader."Posting Date" := "Posting Date";
          if ReportSelection."Print Time" then
            TmpDocumentHeader."Posting Time" := TIME;
          ServiceCommentLine.RESET;
          ServiceCommentLine.SETRANGE("Table Name",ServiceCommentLine."Table Name"::"Service Return Receipt Header");
          ServiceCommentLine.SETRANGE("No.","No.") ;
          if ServiceCommentLine.FINDSET then begin
            TmpDocumentHeader."Comments 01" := ServiceCommentLine.Comment;
            if ServiceCommentLine.NEXT <> 0 then begin
              TmpDocumentHeader."Comments 02" := ServiceCommentLine.Comment;
              if ServiceCommentLine.NEXT <> 0 then begin
                TmpDocumentHeader."Comments 03" := ServiceCommentLine.Comment;
                if ServiceCommentLine.NEXT <> 0 then begin
                  TmpDocumentHeader."Comments 04" := ServiceCommentLine.Comment;
                  if ServiceCommentLine.NEXT <> 0 then begin
                    TmpDocumentHeader."Comments 05" := ServiceCommentLine.Comment;
                  end;
                end;
              end;
            end;
          end;
          Customer.GET("Customer No.");
          if Language.GET(Customer."Language Code") then begin
            TmpDocumentHeader."Language ID" := Language."Windows Language ID";
          end;
          TmpDocumentHeader."No." := "Customer No.";
          TmpDocumentHeader.Name := Name;
          TmpDocumentHeader."Name 2" := "Name 2";
          TmpDocumentHeader.Address := Address;
          TmpDocumentHeader."Address 2" := "Address 2";
          TmpDocumentHeader.City := City;
          TmpDocumentHeader."Post Code" := "Post Code";
          TmpDocumentHeader.Phone := Customer."Phone No.";
          TmpDocumentHeader.FAX := Customer."Fax No.";
          TmpDocumentHeader."Vat Registration No." := Customer."VAT Registration No.";
          TmpDocumentHeader."Tax Office" := Customer."Tax Office";
          TmpDocumentHeader.Profession := Customer.Profession;
          TmpDocumentHeader."Ship-To Code" := "Ship-to Code";
          TmpDocumentHeader."Ship-To Name" := "Ship-to Name";
          TmpDocumentHeader."Ship-To Name 2" := "Ship-to Name 2";
          TmpDocumentHeader."Ship-To Address" := "Ship-to Address";
          TmpDocumentHeader."Ship-To Address 2" := "Ship-to Address 2";
          TmpDocumentHeader."Ship-To City" := "Ship-to City";
          TmpDocumentHeader."Ship-To Post Code" := "Ship-to Post Code";
          if ShipToAddress.GET("Customer No.","Ship-to Code") then begin
            TmpDocumentHeader."Ship-To Phone" := ShipToAddress."Phone No.";
            TmpDocumentHeader."Ship-To FAX" := ShipToAddress."Fax No.";
            TmpDocumentHeader."Ship-To Vat Registration No." := ShipToAddress."VAT Registration No.";
            TmpDocumentHeader."Ship-To Tax Office" := ShipToAddress."Tax Office";
            TmpDocumentHeader."Ship-To Profession" := ShipToAddress.Profession;
          end;
          TmpDocumentHeader."Location Code" := "Location Code";
          TmpDocumentHeader."Location Address" := Address;
          if PaymentMethod.GET("Payment Method Code") then
            TmpDocumentHeader."Payment Method" := PaymentMethod.Description;
          if PaymentTerms.GET("Payment Terms Code") then begin
            TmpDocumentHeader."Payment Terms" := PaymentTerms.Description;
          end;
          if SalespersonPurchaser.GET("Salesperson Code") then begin
            TmpDocumentHeader."Salesperson/Purchaser Name" := SalespersonPurchaser.Name;
          end;
          if ReasonCode.GET("Reason Code") then
            TmpDocumentHeader."Transfer Reason" := ReasonCode.Description;
          TmpDocumentHeader."Due Date" := "Due Date";

          ServiceReturnReceiptLine.SETRANGE("Document No.","No.");
          if ServiceReturnReceiptLine.FINDSET then begin
            repeat
              if ((ServiceReturnReceiptLine.Type <> ServiceReturnReceiptLine.Type::" ")
              or ((ServiceReturnReceiptLine.Type = ServiceReturnReceiptLine.Type::" ")
              and (ReportSelection."Print Empty Type Lines")))
              and not ((ServiceReturnReceiptLine.Type = ServiceReturnReceiptLine.Type::Item)
              and (ServiceReturnReceiptLine.Quantity = 0))
              then begin
                TmpDocumentLine.INIT;
                TmpDocumentLine."Document No." := ServiceReturnReceiptLine."Document No.";
                TmpDocumentLine."Line No." :=   ServiceReturnReceiptLine."Line No.";
                TmpDocumentLine.Type :=  ServiceReturnReceiptLine.Type;
                TmpDocumentLine."No." := ServiceReturnReceiptLine."No.";
                TmpDocumentLine.Description :=  ServiceReturnReceiptLine.Description;
                TmpDocumentLine."Unit Of Measure" := ServiceReturnReceiptLine."Unit of Measure";
                TmpDocumentLine.Quantity := ServiceReturnReceiptLine.Quantity ;
                TmpDocumentHeader."Total Quantity"  += ServiceReturnReceiptLine.Quantity;
                TmpDocumentLine.INSERT;
              end;
            until ServiceReturnReceiptLine.NEXT=0;
          end;
          if ServiceReturnReceiptHeader."Cancellation Type" <> ServiceReturnReceiptHeader."Cancellation Type"::" " then begin
            TmpRelDocLine.INIT;
            TmpRelDocLine."Document No." := ServiceReturnReceiptHeader."No.";
            TmpRelDocLine."Line No." += 10000;
            TmpRelDocLine.Description := ServiceReturnReceiptHeader."Cancel No.";
            TmpRelDocLine.Type := TmpRelDocLine.Type::"Related Doc.";
            TmpRelDocLine.INSERT;
          end;
          TmpDocumentHeader."Signature String 1" := ReportSelection."Signature ID 01";
          TmpDocumentHeader."Signature String 2" := ReportSelection."Signature ID 02";
          TmpDocumentHeader."Signature String 3" := ReportSelection."Signature ID 03";
          TmpDocumentHeader."Signature String 4" := ReportSelection."Signature ID 04";
          TmpDocumentHeader."Signature String 5" := ReportSelection."Signature ID 05";
          TmpDocumentHeader."Number Of Copies" := ReportSelection."Number Of Copies";
          TmpDocumentHeader."Document Copy 1 Descr." := ReportSelection."Document Copy 1 Desc.";
          TmpDocumentHeader."Document Copy 2 Descr." := ReportSelection."Document Copy 2 Desc.";
          TmpDocumentHeader."Document Copy 3 Descr." := ReportSelection."Document Copy 3 Desc.";
          TmpDocumentHeader."Document Copy 4 Descr." := ReportSelection."Document Copy 4 Desc.";
          TmpDocumentHeader."Document Copy 5 Descr." := ReportSelection."Document Copy 5 Desc.";
          TmpDocumentHeader."Maximum Line Per Page" := ReportSelection."Lines Per Page";

          if "Cancellation Type" <> "Cancellation Type"::" " then
            TmpDocumentHeader."Cancellation Sign" := TmpDocumentHeader."Cancellation Sign"::"0";

          TmpDocumentHeader.INSERT;
        end;
        GetItemTrackingInformation(DATABASE::"Service Return Receipt Line",TmpDocumentLine,ReportSelection);
        FormatPages(TmpDocumentHeader, TmpDocumentLine,TmpRelDocLine);
        TaxPrinterMng(TmpDocumentHeader);
    end;

    procedure InitBailment();
    begin
        CLEAR(BailmentLines);
        BailmentLastLineNo := 0;
    end;

    procedure InsertBailment(vDocumentNo : Code[20];vNo : Code[20];vQuantity : Decimal;vUnitPrice : Decimal;vAmount : Decimal;vAmountIncludingVAT : Decimal;vLineDiscount : Decimal;vVAT : Text[30];vUnitofMeasure : Text[30];vDescription : Text[250]);
    begin
        with BailmentLines do begin
          RESET;
          SETRANGE("Document No.",vDocumentNo);
          SETRANGE("No.",vNo);
          SETRANGE("Unit Price",vUnitPrice);
          if FINDSET then begin
            Amount += vAmount;
            Quantity += vQuantity;
            "Amount After Discount" += vAmount;
            "Amount Inc. VAT" += vAmountIncludingVAT;
            "VAT Amount" += vAmountIncludingVAT - vAmount;
            MODIFY;
          end else begin
            BailmentLastLineNo += 10000;
            INIT;
            "Document No." := vDocumentNo;
            "Line No." := BailmentLastLineNo;
            "No." := vNo;
            Amount := vAmount;
            Quantity := vQuantity;
            "Amount After Discount" := vAmount;
            "VAT %" := vVAT;
            "Amount Inc. VAT" := vAmountIncludingVAT;
            "VAT Amount" := vAmountIncludingVAT - vAmount;
            "Unit Of Measure" := vUnitofMeasure;
            "Unit Price" := vUnitPrice;
            "Line Discount %" := vLineDiscount;
            Description := vDescription;
            Bailment := true;
            INSERT;
          end;
        end;
    end;

    procedure GetBailments(var vBailmentLines : Record "Document Line" temporary);
    begin
        vBailmentLines.RESET;
        vBailmentLines.DELETEALL;
        BailmentLines.RESET;
        if BailmentLines.FINDSET then begin
          repeat
            vBailmentLines.INIT;
            vBailmentLines := BailmentLines;
            vBailmentLines.INSERT;
          until BailmentLines.NEXT = 0;
        end;
    end;

    procedure GetItemTrackingInformation(TableID : Integer;var TempDocumentLine : Record "Document Line" temporary;var ReportSelection : Record "Report Selections");
    var
        ItemTrackingManagement : Codeunit "Item Tracking Management";
        TempItemLedgerEntry : Record "Item Ledger Entry" temporary;
        vDocumentNo : Code[20];
        HeaderTableID : Integer;
        ItemTrackingDocManagement : Codeunit "Item Tracking Doc. Management";
        TrackingSpecificationTmp : Record "Tracking Specification" temporary;
    begin
        if not ReportSelection."Print Item Tracking" or (TableID = 0) then begin
          exit;
        end;
        //GR New +
        case TableID of
          DATABASE::"Sales Line":
            HeaderTableID := DATABASE::"Sales Header";
          DATABASE::"Purchase Line":
            HeaderTableID := DATABASE::"Purchase Header";
          DATABASE::"Sales Invoice Line":
            HeaderTableID := DATABASE::"Sales Invoice Header";
          DATABASE::"Sales Cr.Memo Line":
            HeaderTableID := DATABASE::"Sales Cr.Memo Header";
          DATABASE::"Sales Shipment Line":
            HeaderTableID := DATABASE::"Sales Shipment Header";
          DATABASE::"Return Receipt Line":
            HeaderTableID := DATABASE::"Return Receipt Header";
          DATABASE::"Purch. Inv. Line":
            HeaderTableID := DATABASE::"Purch. Inv. Header";
          DATABASE::"Purch. Cr. Memo Line":
            HeaderTableID := DATABASE::"Purch. Cr. Memo Hdr.";
          DATABASE::"Purch. Rcpt. Line":
            HeaderTableID := DATABASE::"Purch. Rcpt. Header";
          DATABASE::"Return Shipment Line":
            HeaderTableID := DATABASE::"Return Shipment Header";
          DATABASE::"Transfer Shipment Line":
            HeaderTableID := DATABASE::"Transfer Shipment Header";
          DATABASE::"Transfer Receipt Line":
            HeaderTableID := DATABASE::"Transfer Receipt Header";
          DATABASE::"Service Invoice Line":
            HeaderTableID := DATABASE::"Service Invoice Header";
          DATABASE::"Service Shipment Line":
            HeaderTableID := DATABASE::"Service Shipment Header";
          DATABASE::"Service Cr.Memo Line":
            HeaderTableID := DATABASE::"Service Cr.Memo Header";
          DATABASE::"Service Return Receipt Line":
            HeaderTableID := DATABASE::"Service Return Receipt Header";
        end;
        //GR New -
        vDocumentNo := GlobalDocNo;
        //GR Old +
        //TempDocumentLine.RESET;
        //TempDocumentLine.SETRANGE("Document No.",vDocumentNo);
        //TempDocumentLine.SETRANGE(Type,TempDocumentLine.Type::Item);
        //IF TempDocumentLine.FINDSET THEN BEGIN
        //  REPEAT
        //    CLEAR(ItemTrackingManagement);
        //    IF ItemTrackingManagement.GetItemTrackingInformation(TableID,TempItemLedgerEntry,TempDocumentLine) THEN BEGIN
        //      InsertItemTrackingInformation(TempDocumentLine,TempItemLedgerEntry);
        //    END;
        //  UNTIL TempDocumentLine.NEXT = 0;
        //END;
        //GR Old -

        //GR New +
        if ItemTrackingDocManagement.RetrieveDocumentItemTracking(TrackingSpecificationTmp,vDocumentNo,HeaderTableID,0) > 0 then begin
          TempDocumentLine.RESET;
          if TempDocumentLine.FINDSET then begin
            repeat
              InsertItemTrackingInformation(TempDocumentLine,TrackingSpecificationTmp);
            until TempDocumentLine.NEXT = 0;
          end;
        end;
        //GR New -
        TempDocumentLine.RESET;
    end;

    procedure InsertItemTrackingInformation(var TempDocumentLine : Record "Document Line" temporary;var TempTrackingSpecification : Record "Tracking Specification" temporary);
    var
        ItemTrackingManagement : Codeunit "Item Tracking Management";
        vDocumentNo : Code[20];
        vLineNo : Integer;
        vType : Integer;
        vItemNo : Code[20];
        GRText002 : TextConst ELL='>Αρ. Παρτίδας: %1',ENU='>Lot No.: %1';
        GRText003 : TextConst ELL='>Σειριακός Αρ.: %1',ENU='>Serial No.: %1';
        GRText004 : TextConst ELL='>Σειριακός Αρ.: %1,Αρ. Παρτίδας: %1',ENU='>Serial No.: %1,Lot No.: %2';
        GRText005 : TextConst ELL=',Ημ/νία Λήξης: %1',ENU=',Exp. Date: %1';
    begin
        //GR Replaced +
        TempTrackingSpecification.RESET;
        TempTrackingSpecification.SETRANGE("Source Ref. No.",TempDocumentLine."Line No.");
        if TempTrackingSpecification.FINDSET then begin
          CLEAR(ItemTrackingManagement);
          vDocumentNo := TempDocumentLine."Document No.";
          vLineNo := TempDocumentLine."Line No." + 10;
          vType := TempDocumentLine.Type;
          vItemNo := TempDocumentLine."No.";
          repeat
            TempDocumentLine.INIT;
            TempDocumentLine."Document No." := vDocumentNo;
            TempDocumentLine."Line No." := vLineNo;
            TempDocumentLine.Type := vType;
            TempDocumentLine."Serial No." := TempTrackingSpecification."Serial No.";
            TempDocumentLine."Lot No." := TempTrackingSpecification."Lot No.";
            TempDocumentLine."Expiration Date" := TempTrackingSpecification."Expiration Date";
            case true of
              (TempDocumentLine."Serial No." <> '') and (TempDocumentLine."Lot No." <> '') : begin
                TempDocumentLine.Description := STRSUBSTNO(GRText004,TempTrackingSpecification."Serial No.",TempTrackingSpecification."Lot No.");
              end;
              (TempDocumentLine."Serial No." <> '') and (TempDocumentLine."Lot No." = '') : begin
                TempDocumentLine.Description := STRSUBSTNO(GRText003,TempTrackingSpecification."Serial No.");
              end;
              (TempDocumentLine."Serial No." = '') and (TempDocumentLine."Lot No." <> '') : begin
                TempDocumentLine.Description := STRSUBSTNO(GRText002,TempTrackingSpecification."Lot No.");
              end;
            end;
            if TempDocumentLine."Expiration Date" <> 0D then begin
              TempDocumentLine.Description += STRSUBSTNO(GRText005,TempTrackingSpecification."Expiration Date");
            end;
            TempDocumentLine.Quantity := ABS(TempTrackingSpecification."Quantity (Base)");
            if (TempDocumentLine."Serial No." = '') and (TempDocumentLine."Lot No." = '') and (TempDocumentLine."Expiration Date" = 0D)
            then begin
              TempDocumentLine.INIT;
            end else begin
              TempDocumentLine.INSERT;
            end;
            vLineNo += 10;
          until TempTrackingSpecification.NEXT = 0;
        end;
        //GR Replaced -
    end;

    procedure TaxPrinterMng(var TmpDocumentHeader : Record "Document Header" temporary);
    var
        MyfSetupL : Record "MYF Setup";
        TaxPrinterDocumentL : Record "Tax Printer Document";
        TaxAmounts : array [5,2] of Text[18];
        TaxFactor : Integer;
        Cntr : Integer;
        Cntr2 : Integer;
        TempVat : Decimal;
    begin
        MyfSetupL.SETRANGE("No. Series", TmpDocumentHeader."No. Series");
        if not MyfSetupL.FINDFIRST then
          exit;

        if MyfSetupL."Tax Printer Document Code" = '' then
          exit;

        TaxPrinterDocumentL.GET(MyfSetupL."Tax Printer Document Code");
        case TaxPrinterDocumentL."Document Sign" of
          TaxPrinterDocumentL."Document Sign"::"+" : TaxFactor := 1;
          TaxPrinterDocumentL."Document Sign"::"-" : TaxFactor := -1;
          TaxPrinterDocumentL."Document Sign"::"0" : TaxFactor := 0;
          TaxPrinterDocumentL."Document Sign"::Opposite : begin
            case TmpDocumentHeader."Cancellation Sign" of
              TmpDocumentHeader."Cancellation Sign"::"+" : TaxFactor := 1;
              TmpDocumentHeader."Cancellation Sign"::"-" : TaxFactor := -1;
              TmpDocumentHeader."Cancellation Sign"::"0" : TaxFactor := 0;
            end;
          end;
        end;

        GLSetup.GET;
        GLSetup.TESTFIELD("Tax Printer Start");
        GLSetup.TESTFIELD("Tax Printer End");

        TmpDocumentHeader."Tax Printer Text 1" := GLSetup."Tax Printer Start" + GLSetup."Tax Printer Separator";
        TmpDocumentHeader."Tax Printer Text 1" += TmpDocumentHeader."Vat Registration No." + GLSetup."Tax Printer Separator";
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // SN PAHPS
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // Customer Card
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // Date-Hour
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // Daily Signature
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // Cumulative Signature
        TmpDocumentHeader."Tax Printer Text 1" += GLSetup."Tax Printer Separator"; // Z Number
        TmpDocumentHeader."Tax Printer Text 1" += TaxPrinterDocumentL.Code + GLSetup."Tax Printer Separator";
        TmpDocumentHeader."Tax Printer Text 1" += MyfSetupL."Tax Series" + GLSetup."Tax Printer Separator";
        TmpDocumentHeader."Tax Printer Text 1" += GetIntegerPos(TmpDocumentHeader."Document No.") + GLSetup."Tax Printer Separator";

        for Cntr := 1 to 5 do
          for Cntr2 := 1 to 2 do
            TaxAmounts[Cntr, Cntr2] := TaxAmountsFormat(0, 2, 18);

        for Cntr := 1 to 5 do
          if VAT_Pct[Cntr] <> '' then begin
            EVALUATE(TempVat,VAT_Pct[Cntr]);
            case true of
              TempVat in [GLSetup."Tax Printer Vat 1", GLSetup."Tax Printer Vat 1_1"] : begin
                TaxAmounts[1,1] := TaxAmountsFormat(VAT_Net_Amount[Cntr]  * TaxFactor, 2, 18);
                TaxAmounts[1,2] := TaxAmountsFormat(VAT_Amount[Cntr]  * TaxFactor, 2, 18);
              end;
              TempVat in [GLSetup."Tax Printer Vat 2", GLSetup."Tax Printer Vat 2_1"] : begin
                TaxAmounts[2,1] := TaxAmountsFormat(VAT_Net_Amount[Cntr]  * TaxFactor, 2, 18);
                TaxAmounts[2,2] := TaxAmountsFormat(VAT_Amount[Cntr]  * TaxFactor, 2, 18);
              end;
              TempVat in [GLSetup."Tax Printer Vat 3", GLSetup."Tax Printer Vat 3_1"] : begin
                TaxAmounts[3,1] := TaxAmountsFormat(VAT_Net_Amount[Cntr]  * TaxFactor, 2, 18);
                TaxAmounts[3,2] := TaxAmountsFormat(VAT_Amount[Cntr]  * TaxFactor, 2, 18);
              end;
              TempVat in [GLSetup."Tax Printer Vat 4"] : begin
                TaxAmounts[4,1] := TaxAmountsFormat(VAT_Net_Amount[Cntr]  * TaxFactor, 2, 18);
                TaxAmounts[4,2] := TaxAmountsFormat(VAT_Amount[Cntr]  * TaxFactor, 2, 18);
              end;
              TempVat in [GLSetup."Tax Printer Vat 5"] : begin
                TaxAmounts[5,1] := TaxAmountsFormat(VAT_Net_Amount[Cntr]  * TaxFactor, 2, 18);
                TaxAmounts[5,2] := TaxAmountsFormat(VAT_Amount[Cntr]  * TaxFactor, 2, 18);
              end;
            end;
          end;

        for Cntr := 1 to 5 do
          TmpDocumentHeader."Tax Printer Text 2" += TaxAmounts[Cntr,1] + GLSetup."Tax Printer Separator";

        for Cntr := 1 to 4 do
          TmpDocumentHeader."Tax Printer Text 2" += TaxAmounts[Cntr,2] + GLSetup."Tax Printer Separator";

        TmpDocumentHeader."Tax Printer Text 2" += TaxAmountsFormat(TmpDocumentHeader."Document Amount Inc. VAT" * TaxFactor, 2, 18)
                                                  + GLSetup."Tax Printer Separator";
        TmpDocumentHeader."Tax Printer Text 2" += '0' + GLSetup."Tax Printer Separator"; //Currency
        TmpDocumentHeader."Tax Printer Text 2" += GLSetup."Tax Printer End";

        TmpDocumentHeader.MODIFY;
    end;

    procedure TaxAmountsFormat(Value : Decimal;DecDigits : Integer;StringLength : Integer) : Text[100];
    var
        TempValue : Decimal;
        IntegerPart : BigInteger;
        DecimalPart : Text[30];
    begin
        if Value <> 0 then begin
          TempValue := ABS(Value);
          IntegerPart := ROUND(TempValue, 1, '<');
          if TempValue - IntegerPart <> 0 then
            DecimalPart := PadString(COPYSTR(FORMAT(TempValue - IntegerPart), 3, DecDigits), DecDigits, '0', 1)
          else
            DecimalPart := PadString('0', DecDigits, '0', 0);
          if Value < 0 then
            exit('-' + FORMAT(IntegerPart) + GLSetup."Decimal Seperator" + DecimalPart)
          else
            exit(FORMAT(IntegerPart) + GLSetup."Decimal Seperator" + DecimalPart);
        end else
          exit('0' + GLSetup."Decimal Seperator" + PadString('0', DecDigits, '0', 0));
    end;

    procedure PadString(Str : Text[200];Length : Integer;Filler : Text[1];Direction : Option Front,Back) : Text[200];
    var
        StrResult : Text[200];
    begin
        StrResult := Str;

        if (STRLEN(StrResult) < Length) then
        begin
          case Direction of
            Direction::Front :
            begin
              StrResult := PADSTR('', Length - STRLEN(StrResult) , Filler )  + StrResult;
            end;
            Direction::Back :
            begin
              StrResult := PADSTR(StrResult, Length, Filler);
            end;
          end;
        end;
        exit(StrResult);
    end;

    local procedure GetIntegerPos(No : Code[20]) : Text[30];
    var
        StartPos : Integer;
        EndPos : Integer;
        IsDigit : Boolean;
        i : Integer;
    begin
        StartPos := 0;
        EndPos := 0;
        if No <> '' then begin
          i := STRLEN(No);
          repeat
            IsDigit := No[i] in ['0'..'9'];
            if IsDigit then begin
              if EndPos = 0 then
                EndPos := i;
              StartPos := i;
            end;
            i := i - 1;
          until (i = 0) or (StartPos <> 0) and not IsDigit;
        end;
        if StartPos <> 0 then
          exit(COPYSTR(No, StartPos))
        else
          exit('');
    end;

    local procedure GetShippingAgent(pCode : Code[10]) ShippingAgentText : Text;
    var
        ShippingAgent : Record "Shipping Agent";
    begin
        // IF pCode<>'' THEN BEGIN
        //  ShippingAgent.GET(pCode);
        //  ShippingAgentText := ShippingAgent.Name;
        //  IF ShippingAgent.Address<>'' THEN
        //    ShippingAgentText += ', '+ShippingAgent.Address;
        //  IF ShippingAgent."Phone No1"<>'' THEN
        //    ShippingAgentText += ', '+ShippingAgent."Phone No1";
        // END;
        exit(FORMAT(ShippingAgentText,250));
    end;
}

