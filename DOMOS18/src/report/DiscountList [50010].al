report 50010 "Discount List"
{
    // version IMP

    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Discount List.rdlc';

    dataset
    {
        dataitem(Customer;Customer)
        {
            column(No_Customer;Customer."No.")
            {
            }
            column(Name_Customer;Customer.Name+' '+Customer."Name 2")
            {
            }
            column(PaymentTerms;PaymentTerms.Description)
            {
            }
            column(CompanyAddress_1_;CompanyAddress[1])
            {
            }
            column(CompanyAddress_2_;CompanyAddress[2])
            {
            }
            column(CompanyAddress_3_;CompanyAddress[3])
            {
            }
            column(CompanyAddress_4_;CompanyAddress[4])
            {
            }
            column(CompanyAddress_5_;CompanyAddress[5])
            {
            }
            column(CompanyInfo_Picture;CompanyInfo.Picture)
            {
            }
            column(CompanyInfo_ISO_Logo;CompanyInfo."ISO Logo")
            {
            }
            column(CompanyAddress_6_;CompanyAddress[6])
            {
            }
            column(CompanyAddress_7_;CompanyAddress[7])
            {
            }
            column(PrintLogo;PrintLogo)
            {
            }
            column(SalesLineDiscCount;SalesLineDiscCount)
            {
            }
            dataitem("Item Discount Group";"Item Discount Group")
            {
                column(Code_ItemDiscountGroup;"Item Discount Group".Code)
                {
                }
                column(Description_ItemDiscountGroup;"Item Discount Group".Description)
                {
                }
                column(Discount;Discount)
                {
                }

                trigger OnAfterGetRecord();
                begin
                    SalesLineDiscount.SETRANGE(Code, Code);
                    SalesLineDiscount.SETRANGE("Sales Code", Customer."No.");
                    SalesLineDiscount.SETFILTER("Ending Date",'>=%1', TODAY);
                    SalesLineDiscount.SETFILTER("Starting Date",'<=%1',TODAY);
                    IF SalesLineDiscount.FINDLAST THEN
                      Discount := SalesLineDiscount."Line Discount %"
                    ELSE BEGIN
                      SalesLineDiscount2.SETRANGE(Type,1); //Ομάδα εκπτώσεων ειδών
                      SalesLineDiscount2.SETRANGE(Code, Code);
                      SalesLineDiscount2.SETRANGE("Sales Type",1);  //Ομάδα εκπτώσεων πελατών
                      SalesLineDiscount2.SETRANGE("Sales Code",Customer."Customer Disc. Group");
                      SalesLineDiscount2.SETFILTER("Ending Date",'>=%1',TODAY);
                      SalesLineDiscount2.SETFILTER("Starting Date",'<=%1',TODAY);
                      IF SalesLineDiscount2.FINDFIRST THEN
                        Discount := SalesLineDiscount2."Line Discount %"
                      ELSE
                        Discount :=0;
                    END;

                    IF MaxStartingDate < SalesLineDiscount."Starting Date" THEN BEGIN
                      MaxStartingDate := SalesLineDiscount."Starting Date";
                    END;
                    IF MaxStartingDate < SalesLineDiscount2."Starting Date" THEN BEGIN
                      MaxStartingDate := SalesLineDiscount2."Starting Date";
                    END;
                    IF (MinEndingDate >SalesLineDiscount."Ending Date") AND (SalesLineDiscount."Ending Date"<>0D) THEN BEGIN
                      MinEndingDate := SalesLineDiscount."Ending Date"
                    END;
                    IF (MinEndingDate >SalesLineDiscount2."Ending Date") AND (SalesLineDiscount2."Ending Date"<>0D) THEN BEGIN
                      MinEndingDate := SalesLineDiscount2."Ending Date"
                    END;
                end;
            }
            dataitem("Sales Line Discount";"Sales Line Discount")
            {
                column(Item_No;"Sales Line Discount".Code)
                {
                }
                column(Item_Description;Item.Description+' '+Item."Description 2")
                {
                }
                column(Item_Discount;"Sales Line Discount"."Line Discount %")
                {
                }
                column(MaxStartingDate;MaxStartingDate)
                {
                }
                column(MinEndingDate;MinEndingDate)
                {
                }

                trigger OnAfterGetRecord();
                begin
                    IF NOT Item.GET(Code) THEN
                      Item.INIT;

                    IF MaxStartingDate < "Starting Date" THEN BEGIN
                      MaxStartingDate := "Starting Date";
                    END;
                    IF (MinEndingDate > "Ending Date") AND ("Ending Date"<>0D) THEN BEGIN
                      MinEndingDate := "Ending Date"
                    END;
                end;

                trigger OnPreDataItem();
                begin
                    SETRANGE("Sales Code", Customer."No.");
                    SETRANGE(Type,0); //specific item
                    SETFILTER("Ending Date",'>=%1', TODAY);
                end;
            }

            trigger OnAfterGetRecord();
            begin
                IF NOT PaymentTerms.GET(Customer."Payment Terms Code") THEN
                  PaymentTerms.INIT;

                SalesLineDiscount.SETRANGE("Sales Code", Customer."No.");
                SalesLineDiscount.SETRANGE(Type,0); //specific item
                SalesLineDiscount.SETFILTER("Ending Date",'>=%1', TODAY);
                SalesLineDiscCount := SalesLineDiscount.COUNT;
                SalesLineDiscount.RESET;

                MaxStartingDate := 0D;
                EVALUATE(MinEndingDate, '31-12-2100');
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(PrintLogo;PrintLogo)
                {
                    CaptionML = ELL='Εκτ. Λογοτύπου',
                                ENU='Print Logo';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport();
    begin
        PrintLogo := TRUE;
    end;

    trigger OnPreReport();
    begin
        CompanyInfo.GET;
        CompanyAddress[1] := CompanyInfo.Name + ', ' + CompanyInfo.Profession;
        CompanyAddress[2] := CompanyInfo.FIELDCAPTION("VAT Registration No.") + ': ' + CompanyInfo."VAT Registration No." + ', ' +
                             CompanyInfo.FIELDCAPTION("Tax Office") + ': ' + CompanyInfo."Tax Office";
        CompanyAddress[3] := CompanyInfo.FIELDCAPTION("E-Mail") + ': ' + CompanyInfo."E-Mail";
        CompanyAddress[4] := CompanyInfo.FIELDCAPTION("Phone No.") + ': ' + CompanyInfo."Phone No." + ', ' +
                             CompanyInfo.FIELDCAPTION("Fax No.") + ': ' + CompanyInfo."Fax No.";
        CompanyAddress[5] := CompanyInfo.Address + ', ' + CompanyInfo."Address 2";
        CompanyAddress[6] := CompanyInfo.City + ', '  + CompanyInfo."Post Code";
        CompanyAddress[7] := CompanyInfo.FIELDCAPTION("Registration No.") + ': ' + CompanyInfo."Registration No.";

        CompanyInfo.CALCFIELDS(Picture);
        CompanyInfo.CALCFIELDS("ISO Logo");
    end;

    var
        PaymentTerms : Record "Payment Terms";
        SalesLineDiscount : Record "Sales Line Discount";
        SalesLineDiscount2 : Record "Sales Line Discount";
        Discount : Decimal;
        CompanyAddress : array [20] of Text[250];
        CompanyInfo : Record "Company Information";
        PrintLogo : Boolean;
        Item : Record Item;
        SalesLineDiscCount : Integer;
        MaxStartingDate : Date;
        MinEndingDate : Date;
}

