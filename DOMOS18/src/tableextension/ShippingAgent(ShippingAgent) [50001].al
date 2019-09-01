tableextension 50001 "Shipping Agent" extends "Shipping Agent"
{
    fields
    {
        field(50000;Address;Text[250])
        {
            CaptionML = ELL='Διεύθυνση',ENU='Address';
            DataClassification = ToBeClassified;
        }
        field(50010;"Phone No. 1";Text[30])
        {
            CaptionML = ELL='Τηλέφωνο 1',ENU='Phone No. 1';
            DataClassification = ToBeClassified;
        }
        field(50020;"Phone No. 2";Text[30])
        {
            CaptionML = ELL='Τηλέφωνο 2',ENU='Phone No. 1';
            DataClassification = ToBeClassified;
        }
        field(50030;"FAX";Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(50040;"City";Text[30])
        {
            CaptionML = ELL='Πόλη',ENU='City';
            DataClassification = ToBeClassified;
        }
        field(50050;"Area";Text[30])
        {
            CaptionML = ELL='Περιοχή',ENU='Area';
            DataClassification = ToBeClassified;
        }
        field(50060;"PostCode";Text[30])
        {
            CaptionML = ELL='Ταχ.Κωδ.',ENU='PostCode';
            DataClassification = ToBeClassified;
        }
    }
    

}