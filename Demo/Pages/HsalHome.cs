using BoDi;
using HitachiQA.Driver;

namespace Demo.Pages
{
    public class HsalHome : BasePage
    {
        public HsalHome(ObjectContainer OC) : base(OC)
        {
        }
        public string URL_PATH = "/";
        public void navigate() => UserActions.Navigate(URL_PATH);
        public Element OpenSearch => Element("//*[@id='SupportNaviSearch']");
        public Element SearchInput => Element("//*[@id='MF_form_phrase']");
        public Element SearchButton => Element("//*[contains(@class, 'SearchBtn')]");
        public Element ResultSearchInput => Element("//input[@title='search query']");

    }
}

