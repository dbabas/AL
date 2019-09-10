pageextension 50009 "Sales Order" extends "Sales Order"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(LineSalesHistory; "Line Sales History FactBox")
            {
                SubPageLink = "Sell-to Customer No."=FIELD("Sell-to Customer No."),"No."=FIELD("No.");
            }
        }


    }
}