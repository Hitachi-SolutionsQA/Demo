using BoDi;
using HitachiQA.Playwright;
using Microsoft.Playwright;

namespace Demo.Pages
{
    public class HsalHome : BasePage
    {
        public HsalHome(ObjectContainer OC) : base(OC)
        {
        }
        public string URL_PATH = "/";
        public async Task navigate() => await this.GotoAsync(URL_PATH);
        public ILocator OpenSearch => Locator("xpath=//*[@id='open-global-search']");
        public ILocator SearchInput => Locator("xpath=//*[@id='site-search-keyword']");
        public ILocator SearchButton => Locator("xpath=//button[@aria-label='search']");
        public ILocator ResultSearchHeader => Locator("xpath=//*[@class='results']");


        public ILocator GetMenuItemByName(string itemName)
        {
            return Locator($"xpath=//ul[@class='menu contact-item']/descendant::*[text()='{itemName}']");
        }

        public ILocator GetButtonByText(string buttonText)
        {
            return Locator($"//button[@value='{buttonText}']");
        }

        public ILocator GetContactFormField(string fieldName)
        {
            return Locator($"xpath=//*[contains(@class, 'field-type-text')][child::label[text()='{fieldName}']]/descendant::input |" +
                            $"//*[contains(@class, 'field-type-text')][child::label[text()='{fieldName}']]/descendant::textarea");
        }

        public ILocator GetDropdownOptionByLabel(string dropdownLabel)
        {
            return Locator($"xpath=//*[@data-field-class='field-type-select'][child::label[text()='{dropdownLabel}']]/descendant::select");
        }

        public ILocator GetFieldToolTip(string fieldName)
        {
            return Locator($"xpath=//*[contains(@class, 'field-type-text')][child::label[text()='{fieldName}']]/descendant::*[contains(@id, 'validation_message')]");
        }
    }
}

