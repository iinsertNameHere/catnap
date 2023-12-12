import "catniplib/FetchInfo"
import "std/os"

var distroid = "nil"
if paramCount() > 0:
    distroid = paramStr(1)

let fetchinfo = GetFetchInfo(distroid)
FetchInfo.Render(fetchinfo)
echo ""