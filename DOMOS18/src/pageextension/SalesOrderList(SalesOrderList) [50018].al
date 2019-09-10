pageextension 50018 "Sales Order List" extends "Sales Order List"
{
    layout
    {
        addlast(Control1)
        {
            field(OrderNetWeight; OrderNetWeight)
            {
                CaptionML = ELL='Καθαρό Βάρος Παραγγελίας',ENU='Order Net Weight';
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord();
    var
        General: Codeunit General;
    begin
        OrderNetWeight := General.CalcSalesHeaderNetWeight(Rec);
    end;

    var
        OrderNetWeight: Decimal;
}