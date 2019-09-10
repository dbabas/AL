page 50000 "Line Sales History FactBox"
{
    // version IMP

    CaptionML = ELL='Ιστορικό Είδους Γραμμής',
                ENU='Line Sales History';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Sales Invoice Line";
    SourceTableView = SORTING(Type,"No.","Bill-to Customer No.","Posting Date")
                      ORDER(Descending)
                      WHERE(Type=CONST(Item));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document No.";"Document No.")
                {
                    DrillDownPageID = "Posted Sales Invoice";

                    trigger OnDrillDown();
                    begin
                        General.LookupPostedSalesInvoice("Document No.");
                    end;
                }
                field("Posting Date";"Posting Date")
                {
                }
                field("Line Discount %";"Line Discount %")
                {
                }
            }
        }
    }

    actions
    {
    }

    var
        General : Codeunit General;
}

