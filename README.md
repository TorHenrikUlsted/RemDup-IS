# RemDup-IS
A tiny shiny app initial screening and r script for removing duplicate references through CSV files


This code only works for ProQuest, Web of science and Scopus and only for one csv per search engine as of yet.
The only thing you have to do, hopefully, is change the csv files in the resources folder and remove the ones you do not need.
You do not need all of them.
If you want more you could implement them yourself or ask me to do so.
Now, if it works correctly, you should only need to change the files and do shift+ctrl/cmd+enter and it should work.


This will open a shiny instance for easier reading through the initial screening. You can add your search string in there and all words in the search string will be highlighted in the abstract text. There are buttons called exclude and include, which adds the articles you are currently at to the include/exclude pile and when you close the shiny instance, the articles in the different piles are added to "included_articles" and "excluded_articles" in the resources folder. 
IMPORTANT: The files are overwritten everytime you close shiny, meaning if you want to keep them, you have to copy them somewhere outside the resources folder. They will also get an ID associatied with them. this ID is the number associated with the article number in the list. this means for instance if you the highest ID you have in the two piles is 18. Then you stopped at number 18 in the list, meaning that you can go directly to number 18 next time you launch the shiny app. Still remember to move the include exclude pile, because it does not start from where you last stopped, the files are overwritten entirely.

In order for this to work you need to undergo a few steps.
1. Web of Science: 
Export references as excel file, IMPORTANT: download "full record", add it to the resources folder and rename it to "wos". Then convert it to CSV.

2. Scopus:
When exporting references, click the arrow button next to "export CSV" and check "Citation information" and "Abstract & keywords", this marks all of it. 	Then add to resources folder and rename to "scopus".

3. ProQuest:
Export references as excel, add to resources folder and rename to "proQuest". Then open the file in excel and save as CSV.
