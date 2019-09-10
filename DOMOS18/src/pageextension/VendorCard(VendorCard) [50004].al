pageextension 50004 "Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(Payments)
        {
            field("Cash Payment Discount %";"Cash Payment Discount %")
            {
                ApplicationArea = All;
            }
            
        }
    }
}