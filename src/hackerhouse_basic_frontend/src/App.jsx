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

  useEffect(() => {
    if (backendActor) {
      setIsLoadingProfile(true);
      backendActor
        .getUserProfile()
        .then((response) => {
          if (response.ok) {
            setUserId(response.ok.id.toString());
            setUserName(response.ok.name);
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

  function handleSubmitUserProfile(event) {
    event.preventDefault();
    const name = event.target.elements.name.value;
    backendActor.setUserProfile(name).then((response) => {
      if (response.ok) {
        setUserId(response.ok.id.toString());
        setUserName(response.ok.name);
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
          console.log(response);
          setSentimentResult(response.ok.result);
          setSentimentConfidence(response.ok.confidence);
        } else if (response.err) {
          console.log(response);
          setSentimentResult(`Error: ${response.err}`);
        } else {
          console.log(response);
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
        </>
      )}
    </main>
  );
}

export default App;
