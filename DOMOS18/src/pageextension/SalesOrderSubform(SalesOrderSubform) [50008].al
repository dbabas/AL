pageextension 50008 "Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        modify("No.")
        {
            StyleExpr = StyleDisc;
        }

        addafter(Description)
        {
            field("Description 2"; "Description 2")
            {
                ApplicationArea = All;
            }

        }
        addafter("Line Discount Amount")
        {
            field("Cust. Group Disc. %"; CustGrpDisc)
            {
                CaptionML = ELL='Εκπτ. % Ομ. Πελάτη',ENU='Cust. Group Disc. %';
                ApplicationArea = All;
            }

        }
        addlast(Control1)
        {
            field("Line Net Weight"; "Net Weight" * Quantity)
            {
                ApplicationArea = All;
            }
            field("Net Weight"; "Net Weight")
            {
                ApplicationArea = All;
            }

        }
    }

    trigger OnAfterGetRecord();
    Begin
        ShowCustGrpDisc();
        SetDiscountColour();
    end;

    var
        CustGrpDisc: decimal;
        StyleDisc: Text[30];

    procedure ShowCustGrpDisc();
    var
        SalesLineDisc: Record "Sales Line Discount";
        It: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        //ITV New +
        CustGrpDisc := 0;
        IF(Type <> Type::Item) OR("No." = '') THEN
            EXIT;
        It.GET("No.");

        SalesHeader.get("Document Type", "Document No.");

        IF("Customer Disc. Group" <> '') AND(It."Item Disc. Group" <> '') THEN BEGIN
            SalesLineDisc.SETRANGE(SalesLineDisc."Sales Type", SalesLineDisc."Sales Type"::"Customer Disc. Group");
            SalesLineDisc.SETRANGE(SalesLineDisc."Sales Code", "Customer Disc. Group");
            SalesLineDisc.SETRANGE(SalesLineDisc.Type, SalesLineDisc.Type::"Item Disc. Group");
            SalesLineDisc.SETRANGE(SalesLineDisc.Code, It."Item Disc. Group");
            SalesLineDisc.SETFILTER("Ending Date", '%1|>=%2', 0D, SalesHeader."Posting Date");
            SalesLineDisc.SETRANGE("Starting Date", 0D, SalesHeader."Posting Date");
            IF SalesLineDisc.FINDFIRST THEN
                CustGrpDisc := SalesLineDisc."Line Discount %";

        END;

        //ITV New -
    end;

    procedure SetDiscountColour()
    begin
        //ITV New +
        StyleDisc := '';
        IF ("Line Discount %" <> CustGrpDisc) AND (Type = Type::Item) AND (Rec."No." <> '') THEN
            StyleDisc := 'Unfavorable';
        //ITV New -
    end;
}