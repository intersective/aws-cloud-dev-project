import React, { useState, useEffect } from 'react';
import Cookies from 'js-cookie';

function MyPage() {
  const [initialDate, setInitialDate] = useState(() => {
    const storedDate = Cookies.get('initialDate');
    return storedDate ? new Date(storedDate) : new Date();
  });

  // store initial date in cookie when component mounts
  useEffect(() => {
    Cookies.set('initialDate', initialDate.toISOString());
  }, [initialDate]);

  return (
    <>
      <header style={{ textAlign: 'center' }}>
        <img src="https://statuspage.practera.com/logo.svg" alt="Practera logo" style={{ width: '50%', maxWidth: '500px' }} />
      </header>
      <br></br>
      <h1>Hello there</h1>
      <p>You modified this on {initialDate.toLocaleString()} ({Intl.DateTimeFormat().resolvedOptions().timeZone})</p>
      <footer>
        <a href="/">Go back to home page</a>
      </footer>
    </>
  );
}

export default MyPage;
