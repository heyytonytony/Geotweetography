
import java.util.HashMap;
import java.awt.Rectangle;
import java.lang.Math;
import java.util.Enumeration;

//Auth info
static String OAuthConsumerKey = "7qBKSzIvHjWWtOvAn3grg";
static String OAuthConsumerSecret = "rnyVF2lfHhOYx2x2HF3N3cPZIuQ9acUQ75qtrYwK9g";
static String AccessToken = "87373158-dGVN5yA8Uz3rCjCP7IKZLd6vbBPPp40h9ZACUA9NA";
static String AccessTokenSecret = "nFqBdzuO9PAnNCEJTx5F4l5sTXRTiXxcQLbZ2SjbAxQ";


//Twitter stream
TwitterStream twitter = new TwitterStreamFactory().getInstance();
String keywords[] = {};

static String [] STATE_NAMES = new String[] {
    "Alabama", "AL", "Alaska", "AK", "Arizona", "AZ", "Arkansas", "AR", "California", "CA",
    "Colorado", "CO", "Connecticut", "CT", "Delaware", "DE", "Florida", "FL", "Georgia", "GA",
    "Hawaii", "HI", "Idaho", "ID", "Illinois", "IL", "Indiana", "IN", "Iowa", "IA",
    "Kansas", "KS", "Kentucky", "KY", "Louisiana", "LA", "Maine", "ME", "Maryland", "MD",
    "Massachusetts", "MA", "Michigan", "MI-", "Minnesota", "MN", "Mississippi", "MS",
    "Missouri", "MO", "Montana", "MT", "Nebraska", "NE", "Nevada", "NV", "New Hampshire", "NH",
    "New Jersey", "NJ", "New Mexico", "NM", "New York", "NY", "North Carolina", "NC",
    "North Dakota", "ND", "Ohio", "OH", "Oklahoma", "OK", "Oregon", "OR", "Pennsylvania", "PA",
    "Rhode Island", "RI", "South Carolina", "SC", "South Dakota", "SD", "Tennessee", "TN",
    "Texas", "TX", "Utah", "UT", "Vermont", "VT", "Virginia", "VA", "Washington", "WA",
    "West Virginia", "WV", "Wisconsin", "WI", "Wyoming", "WY"
};

HashMap states;

PShape mainMap;

//the current hover-over state and latest tweeter
State hoverState = null;
Tweeter hoverTweet = null;

//current displayed tweet
Tweeter curTweeter = null;

//current tweets in sidebar
Queue<Tweeter> sideTweets = new LinkedList<Tweeter>();

//offsets for drawing the map
int offsetX = 395;
int offsetY = 230;

//scale factor for the map
float mapScale = 0.7;

//intial values for data range
int maxValue = 0;
int minValue = 20;

//alpha value assign to colors (used to create a fadded/muted effect)
int standardAlpha = 180;

//background image
PImage bgImage;

//mouseover image
PImage moImage;

//dynamic image of color bar
PImage colorBar;
int colorBarWidth = 250;
int colorBarHeight = 25;

//color values
//full
float maxColorR = 255f;
float maxColorG = 255f;
float maxColorB = 255f;

//mid
float midColorR = 127.5f;
float midColorG = 127.5f;
float midColorB = 255f;

//empty
float minColorR = 0f;
float minColorG = 0f;
float minColorB = 255f;

float midPoint = 0.5;

void setup()
{
    mainMap = loadShape("Blank_US_Map.svg");
    size(1200,800);
    bgImage = loadImage("background3.png");
    moImage = loadImage("mouseoverx.png");
    moImage.resize(330,0);
    states = new HashMap(STATE_NAMES.length);
    for(int i=0;i<STATE_NAMES.length;i+=2)
    {
        states.put(STATE_NAMES[i], new State(STATE_NAMES[i], mainMap.getChild(STATE_NAMES[i+1])));
    }

    _calcColorStates();
    _createColorBar();
    _calcColorBar();

    connectTwitter();
    twitter.addListener(listener);
    twitter.sample();
}

boolean first = true;
void draw()
{
    _calcColorStates();
    _calcColorBar();

    //sleep on the first frame so you don't get that awkward, partially drawn frame
    if(first)
    {
        try
        {
            Thread.sleep(500);
        }
        catch(Exception e){}
        first = false;
    }

    //clear the screen
    background(255);

    //push current coordinate system to apply scale effect
    pushMatrix();

    scale(mapScale);

    //draw states' colours
    Iterator iter = states.values().iterator();
    while(iter.hasNext())
    {
        ((State)iter.next()).draw();
    }

    //pop old coordinate system
    popMatrix();

    //draw color bar border
    int cx = width - 590;
    int cy = height - 210;
    noFill();
    stroke(100,100,0);
    quad(cx-1, cy-1,
            cx+colorBarWidth,cy-1,
            cx+colorBarWidth,cy+colorBarHeight,
            cx-1,cy+colorBarHeight);


    image(colorBar, cx,cy);
    fill(0,0,0,210);
    text(String.format("%,d", minValue),cx,cy + colorBarHeight+15);
    fill(0,0,0,210);
    String maxValueString = String.format("%,d", maxValue);
    text(maxValueString,cx + colorBarWidth - textWidth(maxValueString),cy + colorBarHeight +15);

    //draw the bgImage here so it is mulitplied with already-drawn graphics
    blend(bgImage,0,0,width,height,0,0,width,height,MULTIPLY);

    //draw hover graphics here so they are not part of the multiply blending
    if(hoverState != null)
    {
        String hoverString = hoverState.getName()+":  "+String.format("%,d", hoverState.getValue())+" tweets";
        float x = mouseX + 15;
        float y = mouseY;
        float w = textWidth(hoverString)+5;
        float h = 16;

        image(moImage, x, y);
        fill(230,230,230);
        textSize(18);
        text(hoverString, x+60, y+30);
        text("Latest: ", x+40, y+55);
        textSize(13);
        textLeading(14);
        if(hoverTweet != null)
        {
            text(hoverTweet.getTweet(), x+105, y+40, 210, 70);
        }
        else
        {
            text("none", x+105, y+55);
        }

    }

    //drawing displayed tweet stuff
    //~ if(curTweeter != null)
    //~ {
        //~ PImage twPic = loadImage(curTweeter.getImgURL().toString());
        //~ String twTweet = curTweeter.getTweet();
//~
        //~ //tweet display box
        //~ float twx = width/2 - 150;
        //~ float twy = height*0.84375;
        //~ float tww = 300;
        //~ float twh = 100;
        //~ float twr = 50;
//~
        //~ smooth();
        //~ fill(135,206,250);
        //~ strokeWeight(2);
        //~ stroke(99,99,99);
        //~ beginShape();
        //~ vertex(twx, twy + twr); //top of left side
        //~ bezierVertex(twx, twy, twx, twy, twx + twr, twy); //top left corner
        //~ vertex(twx + tww - twr, twy); //right of top side
        //~ bezierVertex(twx + tww, twy, twx + tww, twy, twx + tww, twy + twr); //top right corner
        //~ vertex(twx + tww, twy + twh - twr); //bottom of right side
        //~ bezierVertex(twx + tww, twy + twh, twx + tww, twy + twh, twx + tww - twr, twy + twh); //bottom right corner
        //~ vertex(twx + twr, twy + twh); //left of bottom side
        //~ bezierVertex(twx, twy + twh, twx, twy + twh, twx, twy + twh - twr); //bottom left corner
        //~ endShape(CLOSE);
//~
        //~ twPic.resize(84,0);
        //~ image(twPic, twx+12, twy+8);
//~
        //~ //image border
        //~ noFill();
        //~ stroke(211,211,211);
        //~ twx += 12;
        //~ twy += 8;
        //~ tww = 84;
        //~ twh = tww;
        //~ twr = 10;
        //~ beginShape();
        //~ vertex(twx, twy + twr); //top of left side
        //~ bezierVertex(twx, twy, twx, twy, twx + twr, twy); //top left corner
        //~ vertex(twx + tww - twr, twy); //right of top side
        //~ bezierVertex(twx + tww, twy, twx + tww, twy, twx + tww, twy + twr); //top right corner
        //~ vertex(twx + tww, twy + twh - twr); //bottom of right side
        //~ bezierVertex(twx + tww, twy + twh, twx + tww, twy + twh, twx + tww - twr, twy + twh); //bottom right corner
        //~ vertex(twx + twr, twy + twh); //left of bottom side
        //~ bezierVertex(twx, twy + twh, twx, twy + twh, twx, twy + twh - twr); //bottom left corner
        //~ endShape(CLOSE);
//~
        //~ //display tweet text
        //~ fill(0,0,0);
        //~ text(twTweet, twx+100, twy+10, 190, 80);
    //~ }
}


void mousePressed()
{
    //trasform mouse coords to account for the transformation applied to the map
    int mX = round(float(mouseX)/mapScale) - offsetX;
    int mY = round(float(mouseY)/mapScale) - offsetY;
    for(int i=0;i<STATE_NAMES.length;i+=2)
    {
        State s = (State)states.get(STATE_NAMES[i]);
        if(s.getName().equals("Alaska") || s.getName().equals("Hawaii"))
        {
            if(s.isNear(mX, mY) && s.sizeTw() > 0)
            {
                curTweeter = s.removeTw();
                break;
            }
        }
        else
        {
            if(s.hover(mX,mY) && s.sizeTw() > 0)
            {
                curTweeter = s.removeTw();
                break;
            }
        }
    }
}

void mouseMoved()
{
    hoverState = null;

    //trasform mouse coords to account for the transformation applied to the map
    int mX = round(float(mouseX)/mapScale) - offsetX;
    int mY = round(float(mouseY)/mapScale) - offsetY;
    for(int i=0;i<STATE_NAMES.length;i+=2)
    {
        State s = (State)states.get(STATE_NAMES[i]);
        if(s.getName().equals("Alaska") || s.getName().equals("Hawaii"))
        {
            if(s.isNear(mX, mY))
            {
                hoverState = s;
                hoverTweet = s.peekLatestTw();
                break;
            }
        }
        else
        {
            if(s.hover(mX,mY))
            {
                hoverState = s;
                hoverTweet = s.peekLatestTw();
                break;
            }
        }
    }
}

void mouseDragged()
{
}

void mouseReleased()
{
}

void _createColorBar()
{
    colorBar = createImage(colorBarWidth,colorBarHeight,ARGB);
}

color _getColor(float f, float m)
{
    float cR,cG,cB;
    if(f < m)
    {
        f /= m;

        cR = (1.0-f)*minColorR + (f)*midColorR;
        cG = (1.0-f)*minColorG + (f)*midColorG;
        cB = (1.0-f)*minColorB + (f)*midColorB;
    }
    else
    {
        f -= m;
        if(m == 1.0)
        {
            f = 0.0;
        }
        else
        {
            f /= (1.0 - m);
        }

        cR = (1.0-f)*midColorR + (f)*maxColorR;
        cG = (1.0-f)*midColorG + (f)*maxColorG;
        cB = (1.0-f)*midColorB + (f)*maxColorB;
    }

    return color(round(cR),round(cG),round(cB), standardAlpha);
}

void _calcColorBar()
{
    colorBar.loadPixels();
    for(int i=0;i<colorBarWidth;i++)
    {
        float f = float(i)/float(colorBarWidth);
        color b = color(200,200,0,standardAlpha);
        for(int j=0;j<colorBarHeight;j++)
        {
            colorBar.set(i,j,_getColor(f,midPoint));
        }
    }
}

void _calcColorStates()
{
    int range = maxValue - minValue;

    float cR, cG, cB;

    for(int i=0;i<STATE_NAMES.length;i+=2)
    {
        State s = (State)states.get(STATE_NAMES[i]);
        float f = float(s.getValue() - minValue) / float(range);

        s.setColor(_getColor(f, midPoint));
    }
}



/**
 * State class to hold state data, hold color, and perform hover operations
 *
 */
 class State
 {
    Rectangle bounds;
    String name;
    Deque<Tweeter> tweets = new LinkedList<Tweeter>();
    PShape pShape;
    int value;
    color c;

    public State(String name, PShape shape)
    {
        this.name = name;
        this.pShape = shape;
        this.value = 0;
        _calcBounds();
    }

    void draw()
    {
        pShape.disableStyle();
        stroke(255,255,255,255);
        strokeWeight(1);
        fill(this.c);
        shape(pShape,offsetX,offsetY);

        stroke(255,0,0);
    }

    String getName()
    {
        return name;
    }

    int getValue()
    {
        return value;
    }

    boolean hover(int x, int y)
    {
        return _inBounds(x,y);
    }

    boolean isNear(int x, int y)
    {
        if(bounds.contains(x,y))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    void setColor(color c)
    {
        this.c = c;
    }

    void setValue(int v)
    {
        this.value = v;
    }

    private void _calcBounds()
    {
        int minX = width, minY = height;
        int maxX = 0, maxY = 0;

        for(int i=0;i<pShape.getVertexCount();i++)
        {
            if(pShape.getVertex(i)[0] < minX)
            {
                minX = round(pShape.getVertex(i)[0]);
            }
            else if(pShape.getVertex(i)[0] > maxX)
            {
                maxX = round(pShape.getVertex(i)[0]);
            }

            if(pShape.getVertex(i)[1] < minY)
            {
                minY = round(pShape.getVertex(i)[1]);
            }
            else if(pShape.getVertex(i)[1] > maxY)
            {
                maxY = round(pShape.getVertex(i)[1]);
            }
        }

        bounds = new Rectangle(minX, minY, (maxX - minX), (maxY - minY));
    }

    private boolean _inBounds(int x, int y)
    {
        if(bounds.contains(x,y))
        {
            if(pShape.contains(x,y))
            {
                return true;
            }
        }
        return false;
    }

    public void drawBounds()
    {
        stroke(250,0,0);
        noFill();
        Rectangle r = bounds;
        quad(  (float)r.getX(),(float)r.getY(),
                (float)(r.getX()+r.getWidth()),(float)r.getY(),
                (float)(r.getX()+r.getWidth()),(float)(r.getY()+r.getHeight()),
                (float) r.getX(),(float)(r.getY()+r.getHeight()));
    }

    public boolean addTw(Tweeter twt)
    {
        return tweets.add(twt);
    }

    public Tweeter peekLatestTw()
    {
        return tweets.peekLast();
    }

    public Tweeter removeTw()
    {
        return tweets.remove();
    }

    public int sizeTw()
    {
        return tweets.size();
    }
 }

/**
 * Tweeter class to hold profile image URL and tweet
 *
 */
class Tweeter
{
    String tweet;
    URL imageURL;

    public Tweeter(URL imgURL, String tweet)
    {
        imageURL = imgURL;
        this.tweet = tweet;
    }

    public URL getImgURL()
    {
        return imageURL;
    }

    public String getTweet()
    {
        return tweet;
    }
}


 // Initial connection
void connectTwitter()
{
    twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
    AccessToken accessToken = loadAccessToken();
    twitter.setOAuthAccessToken(accessToken);
}

// Loading up the access token
private static AccessToken loadAccessToken()
{
    return new AccessToken(AccessToken, AccessTokenSecret);
}

 // This listens for new tweets
StatusListener listener = new StatusListener()
{
    public void onStatus(Status status)
    {

        //println(status.getUser().getName() + " says:  " + status.getText());      //debuggery
        //println("country :  " + status.getUser().getLocation());                  //debuggery

        for(int i=0;i<STATE_NAMES.length;i+=2)
        {
            if(status.getUser().getLocation() != null)
            {
                if (status.getUser().getLocation().contains(STATE_NAMES[i]) || status.getUser().getLocation().contains(STATE_NAMES[i+1]))
                {
                    State s = (State)states.get(STATE_NAMES[i]);
                    s.value++;
                    println(s.name + " :  " + s.value);

                    if(minValue <= s.value) minValue = s.value+1;
                    s.addTw(new Tweeter(status.getUser().getProfileImageURL(), status.getUser().getName() + ": " + status.getText()));
                }
            }

        }
    }

    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice)
    {
        //println("Got a status deletion notice id:" + statusDeletionNotice.getStatusId());
    }
    public void onTrackLimitationNotice(int numberOfLimitedStatuses)
    {
        //println("Got track limitation notice:" + numberOfLimitedStatuses);
    }
    public void onScrubGeo(long userId, long upToStatusId)
    {
        System.out.println("Got scrub_geo event userId:" + userId + " upToStatusId:" + upToStatusId);
    }

    public void onException(Exception ex)
    {
        ex.printStackTrace();
    }
};

