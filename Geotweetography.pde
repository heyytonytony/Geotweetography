
import java.util.HashMap;
import java.awt.Rectangle;
import java.lang.Math;
import java.util.Enumeration;

//Auth info
static String OAuthConsumerKey = "7qBKSzIvHjWWtOvAn3grg";
static String OAuthConsumerSecret = "rnyVF2lfHhOYx2x2HF3N3cPZIuQ9acUQ75qtrYwK9g";
static String AccessToken = null;
static String AccessTokenSecret = null;

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
LinkedList<Tweeter> sideTweets = new LinkedList<Tweeter>();
State sideState = null;
int sideX = 689;
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
PImage bgImage2;

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

//transition
float trans = 0;

//fps display
boolean fpsOn = false;

void setup()
{
    try
    {
        String accessPath = dataPath("access");
        BufferedReader br = new BufferedReader(new FileReader(accessPath));
        AccessToken = br.readLine();
        AccessTokenSecret = br.readLine();
    }
    catch(Exception e)
    {
        println("Exception: " + e.toString());
        exit();
    }

    mainMap = loadShape("Blank_US_Map.svg");
    size(1200,800);
    bgImage = loadImage("background4.png");
    bgImage2 = loadImage("backb2.png");
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
    sideImage = loadImage("sidebar2.png");
    sideFont = createFont("Gill Sans MT",66);
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
    image(bgImage2, 0, 0);

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
    if(sideUp && trans < 1)
        trans += 0.02;
    else if(!sideUp && trans > 0)
        trans -= 0.02;

    pushMatrix();
    scale(1-(trans*0.4));
    translate(0, trans*(height/2 - offsetY/2));

    pushMatrix();
    resetMatrix();
    image(sideImage, sideX+22+500-500*trans, 0);
    textFont(sideFont);
    fill(33,33,33);

    if(sideState != null)
    {
        text(sideState.getName(),sideX+76+500-500*trans,110);
        textSize(20);
        text("Tweets: "+sideState.getValue(),sideX+71+500-500*trans,140);
        textSize(15);
        textLeading(14);

        //populate with up to 6 most recent tweets
        //pull tweets
        sideTweets = sideState.getTw();

        //display tweets
        int sideTwX = sideX+71, sideTwY = 155;
        int ste = sideTweets.size();
        for(int index = 0; index < ste; index++)
        {
            image(sideTweets.get(ste - index - 1).getImg(), sideTwX+500-500*trans, sideTwY);
            text(sideTweets.get(ste - index - 1).getTweet(), sideTwX+90+500-500*trans, sideTwY, 330, 60);
            sideTwY += 103;
        }
        sideState.setSideUpdate(false);
    }
    popMatrix();
    textSize(20);

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
    text(String.format("%,d", minValue),cx,cy + colorBarHeight+17);
    fill(0,0,0,210);
    String maxValueString = String.format("%,d", maxValue);
    text(maxValueString,cx + colorBarWidth - textWidth(maxValueString),cy + colorBarHeight +17);

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
            text(hoverTweet.getTweet(), x+105, y+40, 210, 80);
        }
        else
        {
            text("none", x+105, y+55);
        }

    }

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

    image(title,300-100*trans,0);

    if(fpsOn)
    {
        fill(214,214,214);
        text(frameRate,0,14);
        text(frameCount,5,30);
    }
}


void mousePressed()
{
    if(mouseX > 25 && mouseX < 100 && mouseY > 725 && mouseY < 790){
        playb = !playb;

        if(keys){
          keys = false;
          keywords[0] = keyword;
          if(authed){
            setup();
          }
        }

        if(playb && !init){
          connectTwitter();
          twitter.addListener(listener);
          if (keyword == "" || keyword == "Keyword..." || keyword.length() == 0) twitter.sample();
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
        int mX, mY;
        if(sideUp)
        {
            mX = round(float(mouseX)/mapScale/0.6) - offsetX;
            mY = round(float(mouseY)/mapScale/0.6) - offsetY - height/2;
        }
        else// if(trans == 0)
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
                    sideState = s;
                    sideUp = true;
                    break;
                }

                //clicked outside of any state bound
                sideUp = false;
            }
            else
            {
                if(s.hover(mX,mY))
                {
                    sideState = s;
                    sideUp = true;
                    break;
                }
                //clicked outside of any state bound
                sideUp = false;
            }
        }
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

void keyPressed()
{
    if(key == TAB)
        fpsOn = !fpsOn;
}

void keyReleased()
{
  if(keys && key == ENTER || key == RETURN)
  {
    keys = false;
    keywords[0] = keyword;
    if(authed){
      if (keyword == "" || keyword.length() == 0) twitter.sample();
      else twitter.filter(new FilterQuery().track(keywords));
      setup();
    }
  }
  if(keys && key == BACKSPACE && keyword.length() > 0) keyword = keyword.substring(0,keyword.length()-1);
  else if(keys && textWidth(keyword + key) < 120 && key > 31 && key < 127) keyword = keyword + key;
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
    LinkedList<Tweeter> tweets = new LinkedList<Tweeter>();
    boolean sideUpdate = false;
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
        smooth();
        stroke(255,255,255,255);
        strokeWeight(1);
        fill(this.c);
        shape(pShape,offsetX,offsetY);

        stroke(255,0,0);
        noSmooth();
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

    public LinkedList<Tweeter> getTw()
    {
        return tweets;
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

    public boolean getSideUpdate()
    {
        return sideUpdate;
    }

    public void setSideUpdate(boolean set)
    {
        sideUpdate = set;
    }

 }

/**
 * Tweeter class to hold profile image URL and tweet
 *
 */
class Tweeter
{
    String tweet;
    PImage profileImage;

    public Tweeter(PImage profileImage, String tweet)
    {
        this.profileImage = profileImage;
        this.tweet = tweet;
    }

    public PImage getImg()
    {
        return profileImage;
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
                    if(s.sizeTw() == 6)
                    {
                        s.removeTw();
                    }
                    PImage twImg;
                    try
                    {
                        twImg = loadImage(status.getUser().getProfileImageURL().toString());
                        twImg.resize(78,0);
                    }
                    catch(Exception e)
                    {
                        twImg = loadImage("defaultTweeter.png");
                    }
                    s.addTw(new Tweeter(twImg, status.getUser().getName() + ": " + status.getText()));
                    s.setSideUpdate(true);
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

