using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using TechTalk.SpecFlow;
using HitachiQA;

namespace Demo.StepDefinition
{
    [Binding]
    public class FileComparisonSteps
    {
        IEnumerable<string> actual;
        IEnumerable<string> expected;
        string actualFilePath;
        string expectedFilePath;
        List<string> errors = new List<string>();

        private IEnumerable<string> ReadFile(string filePath)
        {
            FileStream stream = File.OpenRead(filePath);
            using (var streamReader = new StreamReader(stream, Encoding.UTF8))
            {
                string line = string.Empty;
                while ((line = streamReader.ReadLine()) != null)
                {
                    yield return line;
                }
            }
        }

        [Given(@"Text file is loaded from Expected '(.*)' file")]
        public void GivenTextFileIsLoadedFromExpectedFile(string fileName)
        {
            try
            {
                expectedFilePath = Path.GetFullPath($"..\\Data\\Expected\\{fileName}");
            }
            catch
            {
                expectedFilePath = Path.GetFullPath(fileName);
            }
            expected = ReadFile(expectedFilePath);
        }

        [Given(@"FTP output is loaded from Actual '(.*)' file")]
        public void GivenFTPOutputIsLoadedFromActualFile(string fileName)
        {
            try
            {
                actualFilePath = Path.GetFullPath($"..\\Data\\Actual\\{fileName}");
            }
            catch
            {
                actualFilePath = Path.GetFullPath(fileName);
            }
            actual = ReadFile(actualFilePath);
        }

        [When(@"compared line for line")]
        public void WhenComparedLineForLine()
        {
            string match = "";
            foreach(string text in expected)
            {
                if (actual.Contains(text) == true) { match = "match"; }
            }
            if (match != "match")
            {
                errors.Add("No line in Expected file matches any line in actual file");
            }
        }

        [When(@"compared one for one")]
        public void WhenComparedOneForOne()
        {
            var expectedCount = expected.Count();
            var actualCount = actual.Count();
            if (expectedCount != actualCount)
            {
                errors.Add($"line count mismatch expected count : {expectedCount} actual count : {actualCount}");
            }
            for (int index = 0; index < expectedCount || index < actualCount; index++)
            {
                string expectedLine;
                string actualLine;
                if (index < expectedCount)
                {
                    expectedLine = expected.ElementAt(index);
                }
                else
                {
                    actualLine = actual.ElementAt(index);
                    errors.Add($"expected file is missing line : {actualLine}");
                    continue;
                }
                if (index < actualCount)
                {
                    actualLine = actual.ElementAt(index);
                }
                else
                {
                    expectedLine = expected.ElementAt(index);
                    errors.Add($"actual file is missing line : {expectedLine}");
                    continue;
                }
                if (expectedLine.ToLower() != actualLine.ToLower())
                {
                    errors.Add($"mismatch at [{index}] \nactual   : {actualLine} \nexpected : {expectedLine}");
                }
            }
        }

        [Then(@"files match as expected")]
        public void ThenFilesMatchAsExpected()
        {
            if (errors.Any())
            {
                throw new Exception($"file mismatch \nactual file : {actualFilePath} \nexpected file : {expectedFilePath}\n {string.Join("\n", errors)}");
            }
        }
    }
}
