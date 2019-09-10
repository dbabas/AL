tableextension 50006 "Vendor" extends Vendor
{
    fields
    {
        field(50000; "Cash Payment Discount %"; Integer)
        {
            CaptionML = ELL = 'Εκπτ. Μετρητοίς', ENU = 'Cash Payment Discount %';
            DataClassification = ToBeClassified;
        }
    }
}