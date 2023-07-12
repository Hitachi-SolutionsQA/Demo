using BoDi;
using HitachiQA.Playwright;
using Microsoft.Playwright;

namespace HitachiPWSample.Pages
{
    public class HsalHome : BasePage
    {
        public HsalHome(ObjectContainer OC) : base(OC)
        {
        }
        public string URL_PATH = "/";
        public async Task navigate() => await this.GotoAsync(URL_PATH);
        public ILocator ContactUsBtn => Locator("//a[@class='btn btn-primary'][normalize-space()='Contact us']");
        public ILocator SearchBtn => Locator("#open-global-search");
        public ILocator SearchInput => Locator("#site-search-keyword");
        public ILocator SearchIcon => Locator(".gsearch.icon.icon-search");
        public ILocator ResultsNumber => Locator(".results-header > p");

    }
}

