using BoDi;
using HitachiQA.Playwright;
using Microsoft.Playwright;

namespace HitachiPWSample.Pages
{
    public class HsalSearch : BasePage
    {
        public HsalSearch(ObjectContainer OC) : base(OC)
        {
        }
        public ILocator ResultsNumber => Locator(".results-header > p");

    }
}

