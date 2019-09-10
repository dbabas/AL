pageextension 50005 "Item Card" extends "Item Card"
{
    layout
    {
        addafter(Description)
        {
            field("Description 2"; "Description 2")
            {
                ApplicationArea = All;
            }
            field("Foreign Description"; "Foreign Description")
            {
                ApplicationArea = All;
            }
            
        }

        addlast(Item)
        {
            field("Price List Code"; "Price List No.")
            {
                ApplicationArea = All;
            }
        }
    }
}