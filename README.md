# Introduction

Make sure students have access to R and, preferably R Studio interface.

> We can use the POSIT cloud which students can log into free and create a project so that they can use the RStudio interface.
> https://posit.cloud/

Make sure students have access to dataset
\>Download data via a RAW data link on GitHub
\>Link to pull down repo without GitHub is: https://github.com/jrgroves/Rticulate/archive/master.zip
\>We need to tell where to save this zip so we add `destdir="./"` to put it in the project directory

# Objectives

The objective of this lesson is to focus on four basic commands to clean, merge, and present data. Also we will touch on where to find data and best practices when cleaning data for analysis.

## Commands

- Filter / Select: clean data
- Join: left joint and difference between left, right and full
- Pivot: Switch data from long form to wide form
- ggplot: create a visual mapping of the data

## Mission

To visualize the sightings of UFO in the continental U.S. and how they have changes between 1990 and 2010.

# Getting Setup

Any endeavor requires supplies and tools and data cleaning processing is no different. With `R` and other open source software packages, we are lucky because other people, way smarter than I, have already put together code packages that can serve specific tasks, much like tools for specific jobs. Just as there are different types and designs of hammers, there are different packages that may do the same job, it all comes down to personal preference.

The packages we will be using are:
- *tidyverse*: this of this as the "Swiss army knife" for cleaning and presenting data.
- *usethis*: contains a set of commands to work with GitHub
- *sf*: contains a set of commands that lets us create and work with maps

To use packages we have to install the package on our "computer" and then we need to load it into R's memory. Installation uses the command `install_packages(.)` and then we can tell R to "load up" the package in its memory, Matrix style, using `library()`. So you need to enter the following commands in your command line.

``` r
install_packages("usethis")
install_packages("tidyverse")
install_pacakges("sf")

library(usethis)
library(tidyverse)
library(sf)
```

# Getting Dirty to Clean Up

## Getting Data

The first key issue is getting data. Data can come from three main sources:
1) Original Collection. This may be actually going out and measuring something or collecting information or may simply be the transfer of archival data from print to digital formats.
2) Downloads: This can include data from a primary source such as Redfin or Zillow for housing data, from an API source such as a government or industry database/website, or from cloud storage such as OneDrive or GitHub.
3) Scrape It: Web-scaping is the process of exploiting the fact that websites, as pretty as they might be, are still just a code written on a system according to a language. Specifically, HTML "tags" different parts of a website and thus everything on a website as a specific address and all "similar" things are all tagged the same way. With the "filter" command, we can parse a website down and start pulling off what we want. Typically this is legal so long as the data is publicly available (not password protected) and your actions do not impact the ability of a website to provide services.

We are going to use three sources of data which fall into categories (2) and (3). The first is a database tracking UFO sightings downloaded from the National UFO Reporting Center (nuforc.org). The second is from the U.S. Census API that contains the geographic code for maps of the continental U.S. and the third contains historical census data from IPUMS, a site that allows for simple access to census data.

Unfortunately we do not have time to work with the APIs directly, so I have already used APIs to download the data and cleaned it a bit for us and saved it to a GitHub repository. Again, for time and simplicity, use the following command to download the data we need.

``` r
usethis::use_course("https://github.com/jrgroves/Rticulate/archive/master.zip", destdir = "./")
```

Once you are finished, you should see the directory "Rticulate-main" in the **Files** window in your RStudio session.

At this point we have the data on our "computer", but we need to get it into R. There are two types of data you will see. The first has the extension `.RData` and this is data that has been already saved as an R dataframe. The other is `.csv` indicating that this is a comma-based text file. The first can only be read by R while the second can be read by any computer. We like to keep data in the simplest form possible so our ideal would be the `.csv`; however, we need some special stuff which is why the census data is in the R specific format.

To load in our text file we use the command `read.csv()` and to load our R specific data, we simply use `load()`. In the case of the text data, we need to assign the data to an object in R whereas with the R specific data, its object assignment will come with it.

``` r
ufo <- read.csv("./Rticulate-main/ufo.csv")
load("./Rticulate-main/census.RData")
```

Now there is one more little thing to do to ensure our census data is in the right format to create maps. R is object based and there are different types of objects R can work with. The most common is the dataframe (that is what ufo and census are both right now). We want to turn our census object into a special object called a *simple features* or *sf* object because that allows us to treat this as a map. This is why we loaded the *sf* library and we do this using the following command.

``` r
census <- st_as_sf(census)
```

## Observing the Mess

We can always see part of our data using the `head()` command in `R` that shows us the first few rows worth of data. Additionally, we may want to know how to refer to our data so we can use the `names()` command to see a list of the column names for our data. Let's try these for our ufo data object.

``` r
head(ufo)

names(ufo)

 [1] "datetime"             "city"                 "state"               
 [4] "country"              "shape"                "duration..seconds."  
 [7] "duration..hours.min." "comments"             "date.posted"         
[10] "latitude"             "longitude"
```

First we see there is lots of information about each of our UFO sightings ranging from when the sighting offered, where it occurred, the shape of the object, how long it lasted, when the data was posted to the website, and a description of the sighting.

What is nice about this data is it is rather rich and there is lots we can do with it. For example, maybe we want to do an analysis about how people describe the sightings or maybe how those descriptions have changes over the decades. In this case, we can use `R` to analyze the description column and look for key phrases or determine what is common.

We could do an analysis to see if the shape of the object reported is correlated with the time of day, location, or year. Are more of a specific shape seen shortly after a move or book featuring that shape is released?

While rich data is nice, it is also a curse because data takes space. While memory is rather cheap with today's computer, it is easier to items to get lost or for processes to use too much memory with information we do not need for our project.

There is also the possibility of dirty data. Data entry is a human endeavor and, as a result, processes changes, mistakes happen, and things get corrupted. We can see an example of this when we look at the output from the `head(ufo)` command. Notice how that the second line is an observation in Texas, however, the country data is missing (that is what the NA means).

Another issue we may face is that the format of "bridges" between datasets might now be correct. Objects in R can be of various types such as numeric or character. While a human can understand that the numeric version of "1" might be the same as the character version of "1", a computer does not unless you tell it to ignore the difference or make sure they are the same type. We might also have more basic formatting issues. For example, if you look at the states in the UFO data, we see it is the two state abbreviation. On the other hand, typing in `head(census)` reveals that the census data is using the state name and something called a GEOID

> The GEOID is part of what is known as the FIPS code. FIPS stands for Federal Information Processing Standards which are maintained by the National Institute of Standards and Technology (NIST) and is a way to organize federal data. Every state has its own two-digit FIPS code and then every county within a state, as its own three-digit code. For example, the code 17037 is for DeKalb County, Illinois. The first two digits (17) are the state code for Illinois and the last three (037) is the code for the county.

## Cleaning off the dirt

When we say "cleaning data" we are not manipulating the data or removing key observations; that is research dishonesty and one of the deadline sins in research. As a result, it is best to make sure you keep track of ALL data "cleaning" exercises you engage in and to have a reason for each step. One way to do this is to note or comment within your code or script that you write so you can always show a fellow researcher or investigator what you cleaned and why.

### Shave a little off the top

We are going to first going to remove the data that we do not need which is defined by our project parameters.

> We want to look at the number of observations within the continental U.S. in 1990 and 2010.

According to this we know we should keep the columns with the 'datetime', 'state', 'country', 'latitude', and 'longitude' (more on why we are keeping these later). We do this with the `select()` command that is part of the *tidyverse* package.

``` r
ufo.us <- ufo %>%
    select(datetime, state, country, latitude, longitude)
```

Another nice feature of the *tidyverse* package is the ability to use "piped code." This is what the character `%>%` at the end of our first line does. Piped code is sending a result from one line into source for the next line and saves us from having to re-write things and thus helps to make our code easy to read (and replicate).

The first line tells R to assign the object "ufo" to the new object "ufo.us" and then to take that result and plug it into the `select()` command where we tell it to only keep those columns of data. If we do a quick look at the result using the `head(ufo.us)` command we will get to see one of the reasons for cleaning data that we just discussed:

``` r
head(ufo.us)

          datetime state country   latitude   longitude
1 10/10/1949 20:30    tx      us 29.8830556  -97.941111
2 10/10/1949 21:00    tx           29.38421  -98.581082
3 10/10/1955 17:00            gb       53.2   -2.916667
4 10/10/1956 21:00    tx      us 28.9783333  -96.645833
5 10/10/1960 20:00    hi      us 21.4180556 -157.803611
6 10/10/1961 19:00    tn      us 36.5950000  -82.188889
```

Again, we see our country missing in line (2) \[as much as Texas may not want to be part of the U.S. at times, it still is\]. We would like to know how big of a problem this is and, more importantly, how do we overcome it?

### Splitting Time

Before we get to that, however, our project requires the number of sightings in 1990 and 2010 and we see the column 'datetime' has the year of the reported sighting, but it is in the same column with the day and month and time of day, all information we do not need. In this step we will accomplish two different tasks:
- (1) split up the datetime column into two separate columns, and
- (2) translate the date into just the year.

When four small turtles and a rat walked through some green ooze, they mutated into something new. We too are going to mutate our data without the use of green, radioactive ooze, however. Instead, we will use the `mutate()` command. This command, also in our *tidyverse* package will create a new data column with information we give it. The information we are going to give our `mutate()` command is part of the datetime column.

The data in the datetime column is a character data or a "string" that we want to split. More specifically, we want to split the string at the space and then we only want to keep the first part. If you were on your own, a simple Google search would likely turn up the use of the following:

``` r
str_split_i(datetime," ", 1)
```

Out of this result, we really only want to keep the year from the date. While there are several ways to carry out this task, the most direct will be to split the string again, only this time we will split it on the forward slash and keep the third part.

``` r
str_split_i(str_split_i(datetime, " ", 1), "/", 3)
```

Since we want to keep this result in our data, we need to create a new column for it and that is where the `mutate()` command comes in.

``` r
mutate(year = str_split_i(str_split_i(datetime, " ", 1), "/", 3))
```

The commands above are all examples of a "nested" command. Another way to write code is to you "piped" commands. With nested commands we work from the inside out whereas with piped command we feed the result of one line of code directly into the next. Our package *tidyverse* is known for its ability to use piped commands which are denoted with the `%>%` character. You already used this once when we created the **ufo.us** object. We are going to use that again and then add our piped code designator at the end of the second line and then add the mutate command above.

``` r
ufo.us <- ufo %>%
    select(datetime, state, country, latitude, longitude) %>%
    mutate(year = str_split_i(str_split_i(datetime, " ", 1), "/", 3))
```

Once we have split out the year, we can use it to filter our data to keep only sightings in 1990 and 2010, just as our project asks for. The command for this is `filter()` and we will utilize a logical argument as well because we want to keep the observation if the year is either 1990 or 2010. To cod this we use the `|` to denote "or".

``` r
filter(year=="1990" | year=="2010")
```

### America Filter

Next our project requires that we limit our data to the continental U.S. and we have already seen that we might have a data input error with missing countries. So is this worth your effort? Ideally you would want to know how "pervasive" the problem is. Without going into the details, there are about 500 observations where the country code is missing. We are going to use the latitude and longitude help us narrow our data down and then filter out the data missing the state data.

``` r
  filter(latitude > 25 & latitude < 50) %>%
  filter(longitude < -70 & longitude > -125) %>%
  filter(state != "")
```

What is nice about using the piped code is we cleaned all of our data in one single command. This is important when we return to our code and try to remember what it is that we are doing and it is important for replication. In research, we want to make sure we track EVERYTHING we do so that our work can be replicated; otherwise, there is no basis for trust in our results. Furthermore, by doing all of our cleaning in code, anyone can see what we do and know that we are not "fudging the numbers".

### PIVOT...PIVOT!

Ever created a pivot table in Excel or heard of a pivot table in a conversation? What is this?

Really, it is a way of "recasting" data to view it in a different way. Data can come in one of two shapes: wide or long
- Long Data: in this case, we have one observation for each time a piece of data is "created". In our case, our UFO data is in long form because there is a single observations for each individual sighting. Long data is usually pretty good when doing data analysis such as regressions.
- Wide Data: Wide data is great for conveying information and is when data is "aggregated" across one or more dimensions. Wide data is good for creating tables, graphs, or conveying totals.

We are going to want to move our data from "long form" to "wide form" or we want to "pivot" the data. Going from long to wide requires aggregation and our Swiss Army Knife packages, *tidyverse* has a command that allows us to do that.

``` r
  ufo.us2 <- ufo.us %>%
    select(state, year) %>%
    mutate(sight = 1) %>%
    pivot_wider(id_cols = state, names_from = year, names_prefix = "YR",
                values_from = sight, values_fn = sum)
```

What are we doing here? First we are limited the data again, to only what we need and then we create a new column to give our `pivot_wider()` something to count. The last line pivots the data to create a "pivot table" were we aggregate on the state (so now we have one observation for each state) and our columns are going to come from the year the sighting took place.

> NOTE: I have to add a prefix to the new column names because R does not like to start names with numbers.

We then get our values from the new sight column and, finally, we tell the command to add up the value of the sight column and that will be our new data.

# Putting it all together

Now we have a nicely clean data and we need to work on getting the values that we need and then, present the data. We have our UFO data and we have our census data (yeah, remember that?) and we need to bring them together.

Anytime we want to merge data, we need to have some base reference common to the both sources of data. Most commonly that base is a variable that is present in both cases. In our data, we will be using this method. There are other methods, however, that we can use. The most common one I personally use in my research is geography and we could, with more time, do that with this dataset.

We could, since we have the latitude and longitude of the sightings, use that data to merge to the census data (because we have the map data for that), but this takes a bit longer and is "harder" on processing power of computers. For us, we can use the state name and abbreviation and GEOID to merge our data. To do this, we may need to create "bridge" between the two datasets and I was able to do that with a simple Google Search. You can open the bridge file by typing the following into your console.

``` r
bridge <- read.csv("./Rticulate-main/bridge.csv")
```

A quick glance with the `head()` command shows us we have the state name, abbreviation, and GEOID code. All we need to do is merge or join the dataframes together.

When we join data, we can do so with a `left_join()`, `right_join()`, or `full_join()` which corresponds to how we treat unmatched data. The first keeps everything in the first dataframe, whether it matches or not, but only matches from the second. The `right_join()` keeps everything from the second dataframe (the one on the right), but only keeps matching data from the first. The last keeps all data whether they match up or not.

We will start with our UFO data and join our bridge data and then join our census data and we can do it all in one block of code using our piped code.

``` r
  core <- ufo.us %>%
    mutate(Abbr = state) %>%
    left_join(., bridge, by="Abbr") %>%
    left_join(., census, by="GEOID")
```

Opps! We get an error, what happened?

The problem is that we do not have a column of data called "Abbr" in the UFO, it is called something else, state. This is an easy fix using our green ooze command, `mutate()` and create what we need in the ufo.us dataframe. The last line in the code removes some cases where we had data from things outside the U.S. when we limited our data by latitude and longitude. A second problem is that we have incompatible data types in our GEOID variable

``` r
  core <- ufo.us %>%
    mutate(Abbr = state) %>%
    left_join(., bridge, by="Abbr") %>%
    mutate(GEOID = str_pad(as.character(GEOID), side = "left", width = 2,               pad = "0")) %>%
    left_join(., census, by="GEOID") %>%
    filter(!is.na(State))
```

# Find the believers!

To get an idea of what our dataset looks like now, we can use the `summary()` command and the first thing we notice is a scale issue. We want the sightings per person, but there is a vast scale difference between our sightings and our population. How can we fix this?

``` r
core <- core %>%
    mutate(pop_1990 = pop_1990/1000000,
           pop_2010 = pop_2010/1000000)
```

Use `summary()` again and we see we have the scales closer now. We want our data "per person" or in this case "per 1 million persons" so we create a new variable where we divide the sightings by the population and then we want to know how that changed over the time so we will find the percentage change. The second-to-last line removes Hawaii because that just messes up the visual (and people in Hawaii are too busy to see UFOs) and the last line gets us ready to map making.

``` r
mutate(spp_1990 = YR1990/pop_1990,
       spp_2010 = YR2010/pop_2010,
       delta_spp = (spp_2010 - spp_1990)/spp_1990) %>%
filter(GEOID != "15") %>%
st_as_sf()
```

Now, finally, we want to see what we have. While there are lots of ways to display data, we are going to use maps. The last part of the *tidyverse* package we will use is *ggplot* which is a power tool to customizing visualizations. The code for the first map is

``` r
  ggplot(core) +
    geom_sf(aes(fill = spp_1990)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "UFO Sightings per 1 Million Persons in 1990") +
    theme_bw()
```

The first line tells the command where our data is and the `+` is similar to the piped character (`%>%`) but rather than moving a result into the next line as a source, we are "adding a layer" of information. Thus, the second line tells the command what kind of map (geom) to draw and we are using a "simple feature" or geographic map. Inside this command we get to define the aesthetics (`aes()`) of the map and we want to fill our polygons with a gradient based on the number of sightings in 1990 variable.

Next we define the gradient to be use so the low color is a light blue and the high value is a dark blue and missing data will be white, and then we add a title and the last line is just doing some basic cleanup to make the image look nicer.

We can create similar maps for 2010 and for the percentage change

``` r
  ggplot(core) +
    geom_sf(aes(fill = spp_2010)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "UFO Sightings per 1 Million Persons in 2010") +
    theme_bw()
  
  ggplot(core) +
    geom_sf(aes(fill = delta_spp)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "Percentage Change in UFO sightings per 1 Million Person between 1990 and 2010") +
    theme_bw()
```

We can then save these as `.png` files to put into other presentations.

# Conclusion

What we have focused on is the role and act of getting and cleaning up data to turn it into something that tells a story. Some key and important concepts to highlight:
- Make sure to keep your original data in the rawest form possible.
- Double check any data for errors and coding mistakes.
- Do all of your cleaning in code so what you have done is transparent.

A final, and most important comment, however, is to use the larger programing community for help. Whenever you run into an error or wonder how to do something, just search in Google and you likely find an article in one of the several coding
