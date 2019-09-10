pageextension 50010 "Customer Card" extends "Customer Card"
{
    layout
    {
        modify("Allow Line Disc.")
        {
            Enabled = false;
        }
    }

    actions
    {
        addlast(Action82)
        {
            action("Discount List")
            {
                CaptionML = ELL = 'Λίστα Εκπτώσεων', ENU = 'Discount List';
                Image = Discount;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Cust: Record Customer;
                begin
                    Cust := Rec;
                    CurrPage.SETSELECTIONFILTER(Cust);
                    REPORT.RUNMODAL(REPORT::"Discount List", TRUE, FALSE, Cust);
                end;
            }
        }
    }
}