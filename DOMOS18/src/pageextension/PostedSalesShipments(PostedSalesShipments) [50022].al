pageextension 50022 "Posted Sales Shipments" extends "Posted Sales Shipments"
{
    layout
    {
        addlast(Control1)
        {
            field("External Document No."; "External Document No.")
            {
                ApplicationArea = All;
            }
            
        }
    }
}