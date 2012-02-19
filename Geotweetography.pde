
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
String keywords[] = {"lol"};

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

//current tweets in sidebar
Queue<Tweeter> sideTweets = new LinkedList<Tweeter>();
State sideState = null;
float sideX = 689;
PFont sideFont;

//offsets for drawing the map
int offsetX = 395;
int offsetY = 230;

//scale factor for the map
float mapScale = 0.7;

//intial values for data range
int maxValue = 0;
int minValue = 1;

//alpha value assign to colors (used to create a fadded/muted effect)
int standardAlpha = 180;

//background image
PImage bgImage;

//mouseover image
PImage moImage;
PImage moImage2;
PImage title;
PImage over;

//sidebar image
PImage sideImage;
boolean sideUp = false;

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

//play button
boolean playb = false;
boolean init = false;
PImage play, pause;

//keyword spot
boolean keys = false;
PImage keyw, keyw2;
String keyword = "Keyword...";
String curs = "";
int ci = 0;
boolean authed = false;

void setup()
{
    mainMap = loadShape("Blank_US_Map.svg");
    size(1200,800);
    bgImage = loadImage("background4.png");
    moImage = loadImage("mouseoverx.png");
    moImage2 = loadImage("mouseover2.png");
    title = loadImage("title.png");
    over = loadImage("overlay.png");
    moImage.resize(330,0);
    moImage2.resize(330,0);
    play = loadImage("play.png");
    pause = loadImage("pause.png");
    keyw = loadImage("keyword.png");
    keyw2 = loadImage("keyword2.png");
    sideImage = loadImage("sidebar.png");
    states = new HashMap(STATE_NAMES.length);
    minValue = 1;
    for(int i=0;i<STATE_NAMES.length;i+=2)
    {
        states.put(STATE_NAMES[i], new State(STATE_NAMES[i], mainMap.getChild(STATE_NAMES[i+1])));
    }

    _calcColorStates();
    _createColorBar();
    _calcColorBar();
}

boolean first = true;
void draw()
{
    _calcColorStates();
    _calcColorBar();
    background(0);

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

    //shrink map if sidebar is up, display sidebar and tweets
    if(sideUp)
    {
        pushMatrix();
        scale(0.6);
        translate(0, height/2 - offsetY/2);

        pushMatrix();
        resetMatrix();
        image(sideImage, sideX, 0);
        sideFont = createFont("Gill Sans MT",66);
        textFont(sideFont);
        fill(33,33,33);
        text(sideState.getName(),sideX+61,110);
        textSize(20);
        text("Tweets: "+sideState.getValue(),sideX+56,140);

        //populate with up to 6 most recent tweets

        //TODO

        popMatrix();
    }

    if(hoverState != null)
    {
        float x = mouseX + 15;
        float y = mouseY;
        image(moImage2, x, y);
    }

    //draw the bgImage
    image(bgImage,0,0);

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

    image(over,0,0);

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
        text("Latest: ", x+43, y+55);
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

    if(sideUp)
        popMatrix();

    //play button
    if(!playb) image(play,30,730);
    else image(pause,30,730);

    //keyword
    if(!keys) image(keyw,110,730);
    else image(keyw2,100,720);
    fill(255, 255, 255, 255);
    textSize(30);
    if(keys)text(keyword+curs, 125, 770);
    else text(keyword, 125, 770);
    if (ci == 12){
      if(curs == "") curs = "|";
      else curs = "";
      ci = 0;
    }
    else ci++;
    textSize(18);

    image(title,300,0);
}


void mousePressed()
{
    if(mouseX > 25 && mouseX < 100 && mouseY > 725 && mouseY < 790){
        playb = !playb;
        if(playb && !init){
          connectTwitter();
          twitter.addListener(listener);
          if (keyword == "" || keyword == "Keyword..." ) twitter.sample();
          else twitter.filter(new FilterQuery().track(keywords));
          init = true;
        }
    }
    else if(mouseX > 100 && mouseX < 350 && mouseY > 725 && mouseY < 790){
        keys = !keys;
        if(keys && keyword == "Keyword...") keyword = "";
    }
    else
    {
        keys = false;
        //trasform mouse coords to account for the transformation applied to the map
        if(!sideUp)
        {
            int mX = round(float(mouseX)/mapScale) - offsetX;
            int mY = round(float(mouseY)/mapScale) - offsetY;
            for(int i=0;i<STATE_NAMES.length;i+=2)
            {
                State s = (State)states.get(STATE_NAMES[i]);
                if(s.getName().equals("Alaska") || s.getName().equals("Hawaii"))
                {
                    if(s.isNear(mX, mY))
                    {
                        sideState = s;
                        sideUp = !sideUp;
                        break;
                    }
                }
                else
                {
                    if(s.hover(mX,mY))
                    {
                        sideState = s;
                        sideUp = !sideUp;
                        break;
                    }
                }
            }
        }
        else
            sideUp = !sideUp;
    }
}

void mouseMoved()
{
    hoverState = null;

    //trasform mouse coords to account for the transformation applied to the map
    int mX, mY;
    if(sideUp)
    {
        mX = round(float(mouseX)/mapScale/0.6) - offsetX;
        mY = round(float(mouseY)/mapScale/0.6) - offsetY - height/2;
    }
    else
    {
        mX = round(float(mouseX)/mapScale) - offsetX;
        mY = round(float(mouseY)/mapScale) - offsetY;
    }
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

void keyReleased(){
  if(keys && key == ENTER || key == RETURN) {
    keys = false;
    keywords[0] = keyword;
    if(authed){
      if (keyword == "") twitter.sample();
      else twitter.filter(new FilterQuery().track(keywords));
      setup();
    }
  }
  if(keys && key == BACKSPACE && keyword.length() > 0) keyword = keyword.substring(0,keyword.length()-1);
  else if(keys && textWidth(keyword + key) < 120) keyword = keyword + key;
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
    authed = true;
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
      if(playb){
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

