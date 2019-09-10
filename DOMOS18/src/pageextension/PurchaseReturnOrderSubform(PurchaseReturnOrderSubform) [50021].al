pageextension 50021 "Purchase Return Order Subform" extends "Purchase Return Order Subform"
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
    }

}