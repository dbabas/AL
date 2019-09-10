pageextension 50007 "Item List" extends "Item List"
{
    layout
    {
        addafter(Description)
        {
            field("Description 2"; "Description 2")
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