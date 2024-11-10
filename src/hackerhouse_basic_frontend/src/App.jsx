import { useState, useEffect } from "react";
import NfidLogin from "./components/NfidLogin";

function App() {
  const [backendActor, setBackendActor] = useState();
  const [userId, setUserId] = useState();
  const [userName, setUserName] = useState();
  const [sentimentResult, setSentimentResult] = useState();
  const [sentimentConfidence, setSentimentConfidence] = useState();
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);
  const [userResults, setUserResults] = useState([]);
  const [isLoadingResults, setIsLoadingResults] = useState(false);

  useEffect(() => {
    if (backendActor) {
      setIsLoadingProfile(true);
      backendActor
        .getUserProfile()
        .then((response) => {
          if (response.ok) {
            setUserId(response.ok.id.toString());
            setUserName(response.ok.name);
            // Load user's results history after profile is loaded
            loadUserResults();
          } else if (response.err) {
            console.log("No existing profile found:", response.err);
          }
        })
        .catch((error) => {
          console.error("Error fetching profile:", error);
        })
        .finally(() => {
          setIsLoadingProfile(false);
        });
    }
  }, [backendActor]);

  const loadUserResults = () => {
    if (!backendActor) return;

    setIsLoadingResults(true);
    backendActor.getUserResults()
      .then((response) => {
        if (response.ok) {
          const parsedResults = response.ok.results.map(result => {
            try {
              return JSON.parse(result);
            } catch (e) {
              console.error("Error parsing result:", e);
              return null;
            }
          }).filter(result => result !== null);
          setUserResults(parsedResults);
        } else if (response.err) {
          console.log("Error loading results:", response.err);
        }
      })
      .catch((error) => {
        console.error("Error fetching results:", error);
      })
      .finally(() => {
        setIsLoadingResults(false);
      });
  };

  function handleSubmitUserProfile(event) {
    event.preventDefault();
    const name = event.target.elements.name.value;
    backendActor.setUserProfile(name).then((response) => {
      if (response.ok) {
        setUserId(response.ok.id.toString());
        setUserName(response.ok.name);
        loadUserResults(); // Load results after setting profile
      } else if (response.err) {
        setUserId(response.err);
      } else {
        console.error(response);
        setUserId("Unexpected error, check the console");
      }
    });
    return false;
  }

  function handleSentimentAnalysis(event) {
    event.preventDefault();
    const paragraph = event.target.elements.paragraph.value;
    setIsAnalyzing(true);
    setSentimentResult(null);
    setSentimentConfidence(null);

    backendActor
      .outcall_ai_model_for_sentiment_analysis(paragraph)
      .then((response) => {
        if (response.ok) {
          setSentimentResult(response.ok.result);
          setSentimentConfidence(response.ok.confidence);

          // Add the new result to the existing results
          const newResult = {
            text: paragraph,
            sentiment: response.ok.result,
            confidence: response.ok.confidence
          };
          setUserResults(prevResults => [...prevResults, newResult]);
        } else if (response.err) {
          console.log(response);
          setSentimentResult(`Error: ${response.err}`);
        } else {
          console.error(response);
          setSentimentResult("Unexpected error, check the console");
        }
      })
      .finally(() => {
        setIsAnalyzing(false);
      });
    return false;
  }

return (
    <main>
      <img src="/logo2.svg" alt="DFINITY logo" />
      <br />
      <br />
      <h1>Welcome to Fredgido's IC AI Hacker House!</h1>
      {!backendActor && (
        <section id="nfid-section">
          <NfidLogin setBackendActor={setBackendActor}></NfidLogin>
        </section>
      )}
      {backendActor && (
        <>
          {isLoadingProfile ? (
            <p>Loading profile...</p>
          ) : !userName ? (
            <form action="#" onSubmit={handleSubmitUserProfile}>
              <label htmlFor="name">Enter your name: &nbsp;</label>
              <input id="name" alt="Name" type="text" />
              <button type="submit">Save</button>
            </form>
          ) : (
            <p>Welcome back, {userName}!</p>
          )}
          {userId && <section className="response">{userId}</section>}

          <hr className="my-4" />

          <form action="#" onSubmit={handleSentimentAnalysis}>
            <label htmlFor="paragraph">
              Enter text for sentiment analysis: &nbsp;
            </label>
            <textarea
              id="paragraph"
              rows="4"
              className="w-full p-2 border rounded"
            />
            <button type="submit" disabled={isAnalyzing} className="mt-2">
              {isAnalyzing ? "Analyzing..." : "Analyze Sentiment"}
            </button>
          </form>

          {sentimentResult && (
            <section className="response mt-4">
              <p>
                <strong>Sentiment:</strong> {sentimentResult}
              </p>
              {sentimentConfidence && (
                <p>
                  <strong>Confidence:</strong>{" "}
                  {(sentimentConfidence * 100).toFixed(2)}%
                </p>
              )}
            </section>
          )}

          <hr className="my-4" />
          <section className="mt-4">
            <h2 className="text-xl font-bold mb-3">Your Analysis History</h2>
            {isLoadingResults ? (
              <p>Loading history...</p>
            ) : userResults.length > 0 ? (
              <div className="space-y-4">
                {userResults.map((result, index) => (
                  <div key={index} className="p-4 border rounded">
                    <p className="mb-2"><strong>Text:</strong> {result.text}</p>
                    <p><strong>Sentiment:</strong> {result.sentiment}</p>
                    <p><strong>Confidence:</strong> {(result.confidence * 100).toFixed(2)}%</p>
                  </div>
                ))}
              </div>
            ) : (
              <p>No previous analyses found.</p>
            )}
          </section>
        </>
      )}
    </main>
  );
}

export default App;
