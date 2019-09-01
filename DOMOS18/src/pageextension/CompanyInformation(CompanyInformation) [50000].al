pageextension 50000 "Company Information" extends "Company Information"
{
    layout
    {
        addlast(Payments)
        {
            field("Bank Name 4"; "Bank Name 4")
            {
                ApplicationArea = All;
            }
            field("Bank Account No. 4"; "Bank Account No. 4")
            {
                ApplicationArea = All;
            }
            
        }

        addafter(TAXIS)
        {
            Group(ISO)
            {
                field("ISO Logo";"ISO Logo")
                {
                    ApplicationArea = All;
                }
                

            }
        }
    }
}