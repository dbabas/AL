report 50007 "Items With No Transactions"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Items With No Transactions.rdlc';
    CaptionML = ELL='Μη κινηθέντα είδη',
                ENU='Items With No Transactions';

    dataset
    {
        dataitem(Item;Item)
        {
            RequestFilterFields = "No.","Date Filter";
            column(ReportFilter_;DateFilterCaption)
            {
            }
            column(ItemFilters;Item.TABLECAPTION + ': ' + ItemFilter)
            {
            }
            column(ItemNo_;Item."No.")
            {
            }
            column(PostingDate_;PostingDate)
            {
            }
            column(EntryType_;EntryType)
            {
            }
            column(DocType_;DocType)
            {
            }
            column(LocationCode_;LocationCode)
            {
            }
            column(ShowHide_;ShowHide)
            {
            }
            column(Company_Name_Caption;COMPANYNAME)
            {
            }
            column(User_ID_Caption;USERID)
            {
            }
            column(ItemVendor;Item."Vendor No.")
            {
            }
            column(LastPurchCost;Item."Last Purchase Cost")
            {
            }
            column(Inv;It.Inventory)
            {
            }
            column(ItemDesc;Item.Description)
            {
            }

            trigger OnAfterGetRecord();
            begin
                firstloop := true;
                CLEAR(EmptyILE);
                CLEAR(ItemNo);
                CLEAR(PostingDate);
                CLEAR(EntryType);
                CLEAR(DocType);
                CLEAR(LocationCode);
                
                StartDate := Item.GETRANGEMIN("Date Filter");
                EndDate := Item.GETRANGEMAX("Date Filter");
                
                ILE.RESET;
                ILE.SETRANGE("Item No.",Item."No.");
                ILE.SETRANGE("Posting Date",StartDate,EndDate);
                if ILE.FINDSET then begin
                  CurrReport.SKIP;
                  ItemNo := Item."No.";
                  ShowHide := true;
                  firstloop := false;
                  EmptyILE := true;
                end;
                It.GET(Item."No.");
                It.SETRANGE("Date Filter",0D,EndDate);
                It.CALCFIELDS(Inventory);
                
                /*
                IF ILE.FINDSET THEN BEGIN
                  REPEAT
                  IF firstloop THEN BEGIN
                    firstloop := FALSE;
                    PrevPostingDate := ILE."Posting Date";
                    ItemNo := ILE."Item No.";
                    PostingDate := ILE."Posting Date";
                    EntryType := FORMAT(ILE."Entry Type");
                    DocType := FORMAT(ILE."Document Type");
                    LocationCode :=ILE."Location Code";
                    ShowHide := TRUE;
                  END ELSE BEGIN
                    IF (PrevPostingDate <= ILE."Posting Date") THEN BEGIN
                      ItemNo := ILE."Item No.";
                      PostingDate := ILE."Posting Date";
                      EntryType := FORMAT(ILE."Entry Type");
                      DocType := FORMAT(ILE."Document Type");
                      LocationCode :=ILE."Location Code";
                      ShowHide := TRUE;
                    END ELSE
                      ShowHide := FALSE;
                  END;
                
                  IF NOT EmptyILE THEN BEGIN
                    ILE.SETFILTER("Posting Date",DateFilter2);
                    IF NOT ILE.ISEMPTY THEN BEGIN
                      ShowHide := FALSE;
                    END;
                  END;
                  UNTIL ILE.NEXT = 0;
                END;
                */

            end;

            trigger OnPreDataItem();
            begin
                ItemFilter := Item.GETFILTERS;
                DateFilter2 := FORMAT(DateFilter) + '..';
                DateFilterCaption := Item.FIELDCAPTION("Date Filter") + ':' + DateFilter2;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        label(ItemNo_Label;ELL='Κωδικός Είδους',
                           ENU='Item No.')
        label(PostingDate_Label;ELL='Ημερομηνία Καταχώρησης',
                                ENU='Posting Date')
        label(EntryType_Label;ELL='Τύπος Εγγραφής',
                              ENU='Entry Type')
        label(DocumentType_Label;ELL='Τύπος Παραστατικού',
                                 ENU='Document Type')
        label(LocationCode_Label;ELL='Κωδ. Αποθήκης',
                                 ENU='Location Code')
        label(Item_Without_Trans_Label;ELL='Μη κινηθέντα Είδη',
                                       ENU='Item Without Transactions')
        label(Page_Label;ELL='Σελίδα : ',
                         ENU='Page : ')
        label(Inv_Label;ELL='Απόθεμα',
                        ENU='Inventory')
        label(Vendor_Label;ELL='Προμηθευτής',
                           ENU='Vendor')
        label(Last_Cost_label;ELL='Τελ. Τιμή Αγοράς',
                              ENU='Last Purchase Cost')
        label(Item_Desc_Label;ELL='Περιγραφή',
                              ENU='Description')
    }

    trigger OnPreReport();
    begin
        //IF (FORMAT(DateFilter) = '') THEN
        //  ERROR(RCText001);
    end;

    var
        DateFilter : Date;
        DateFilter2 : Text[250];
        DateFilterCaption : Text[250];
        ItemFilter : Text[250];
        ILE : Record "Item Ledger Entry";
        PILE : Record "Phys. Inventory Ledger Entry";
        ItemNo : Code[20];
        PostingDate : Date;
        PrevPostingDate : Date;
        EntryType : Text[50];
        DocType : Text[50];
        LocationCode : Code[20];
        ShowHide : Boolean;
        RCText001 : TextConst ELL='Το πεδίο Ημερομηνία πρέπει να μην είναι κενό ',ENU='Date must have a value';
        firstloop : Boolean;
        EmptyILE : Boolean;
        StartDate : Date;
        EndDate : Date;
        It : Record Item;
}

