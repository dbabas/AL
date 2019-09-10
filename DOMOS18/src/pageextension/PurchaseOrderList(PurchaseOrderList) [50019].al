pageextension 50019 "Purchase Order List" extends "Purchase Order List"
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
        OrderNetWeight := General.CalcPurchHeaderNetWeight(Rec);
    end;

    var
        OrderNetWeight: Decimal;
}