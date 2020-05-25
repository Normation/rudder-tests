# rudder-tests
Rework of rtf

All scenarios run result in a local `result.xml` file in JUnit format.
It can easily be read using tools such as xunit-viewer.

```
# To produce an html report
xunit-viewer -r result.xml -o result.html

# To render it in the console
xunit-viewer -c -r ./result.xml
```
