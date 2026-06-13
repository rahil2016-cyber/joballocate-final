class ResumeHtmlTemplates {
  static const String premiumTemplate = r'''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap');

    :root {
      --primary: #2aa198;
      --secondary: #46a8a8;
      --text-dark: #333333;
      --text-light: #666666;
      --border-color: #000000;
      --sidebar-bg: #ffffff;
    }

    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact;
    }

    body {
      font-family: 'Outfit', 'Arial', sans-serif;
      margin: 0;
      padding: 0;
      background: #f5f5f5;
      color: var(--text-dark);
      font-size: 11px;
    }

    .container {
      display: flex;
      width: 210mm;
      min-height: 297mm;
      margin: 0 auto;
      background: white;
    }

    .left {
      width: 32%;
      background: var(--sidebar-bg);
      padding: 30px 20px;
      border-right: 1px solid #eeeeee;
    }

    .profile-img {
      width: 120px;
      height: 120px;
      border-radius: 50%;
      object-fit: cover;
      display: block;
      margin: 0 auto 30px auto;
      border: 3px solid #f0f0f0;
    }

    .left-section {
      margin-bottom: 25px;
    }

    .left-section h2 {
      font-size: 13px;
      font-weight: 800;
      color: #000000;
      margin: 0 0 8px 0;
      padding-bottom: 5px;
      border-bottom: 1.5px solid var(--border-color);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .left-section p, .left-section li {
      margin: 5px 0;
      line-height: 1.4;
    }

    .left-section ul {
      padding-left: 15px;
      margin: 0;
    }

    .contact-label {
      color: var(--primary);
      font-weight: 700;
      margin-top: 8px;
      display: block;
    }

    .right {
      width: 68%;
      padding: 35px 30px;
    }

    h1 {
      color: var(--primary);
      font-size: 28px;
      font-weight: 800;
      margin: 0 0 25px 0;
      letter-spacing: -0.5px;
    }

    .right-section {
      margin-bottom: 25px;
    }

    .right-section h2 {
      font-size: 13px;
      font-weight: 800;
      color: #000000;
      margin: 0 0 10px 0;
      padding-bottom: 5px;
      border-bottom: 1.5px solid var(--border-color);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .right-section p {
      margin: 8px 0;
      line-height: 1.5;
      color: var(--text-light);
    }

    .highlight {
      color: var(--primary);
      font-weight: 700;
      font-size: 12px;
      margin-bottom: 3px;
      display: block;
    }

    .sub-head {
      color: var(--primary);
      font-weight: 700;
      margin-bottom: 4px;
      display: block;
    }

    .details-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      margin-top: 10px;
    }

    .detail-item b {
      color: var(--text-light);
      font-weight: 400;
      display: block;
      font-size: 10px;
    }

    .detail-item span {
      font-weight: 600;
    }

    .edu-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
    }

    .edu-table th {
      text-align: left;
      font-size: 11px;
      font-weight: 800;
      color: var(--primary);
      padding: 8px 5px;
      border: none;
    }

    .edu-table td {
      padding: 8px 5px;
      vertical-align: top;
      color: var(--text-light);
      border: none;
    }

    .edu-label {
      color: var(--text-dark);
      font-weight: 700;
      width: 100px;
    }

    .bullet-list {
      padding-left: 15px;
      margin: 5px 0;
    }

    .bullet-list li {
      margin-bottom: 5px;
      color: var(--text-light);
    }

    .date-range {
      color: var(--primary);
      font-weight: 600;
      font-size: 10px;
      margin-left: 5px;
    }

    @media print {
      body { background: white; }
      .container { border: none; box-shadow: none; margin: 0; }
    }
  </style>
</head>
<body>
<div class="container">
  <div class="left">
    <img src="{{profile_image}}" class="profile-img"/>
    <div class="left-section">
      <h2>GET IN TOUCH!</h2>
      <span class="contact-label">Mobile:</span>
      <p>{{phone}}</p>
      <span class="contact-label">Email:</span>
      <p>{{email}}</p>
    </div>
    <div class="left-section">
      <h2>SKILLS</h2>
      <ul class="bullet-list">
        {{skills}}
      </ul>
    </div>
    <div class="left-section">
      <h2>LANGUAGES KNOWN</h2>
      <p>{{languages}}</p>
    </div>
    <div class="left-section">
      <h2>CERTIFICATIONS</h2>
      <ul class="bullet-list">
        {{certifications}}
      </ul>
    </div>
  </div>
  <div class="right">
    <h1>{{name}}</h1>
    <div class="right-section">
      <h2>RESUME SUMMARY</h2>
      <p>{{summary}}</p>
    </div>
    <div class="right-section">
      <h2>PERSONAL DETAILS</h2>
      <div class="details-grid">
        <div class="detail-item">
          <b>Current Location</b>
          <span>{{location}}</span>
        </div>
        <div class="detail-item">
          <b>Date of Birth</b>
          <span>{{dob}}</span>
        </div>
        <div class="detail-item">
          <b>Gender</b>
          <span>{{gender}}</span>
        </div>
      </div>
    </div>
    <div class="right-section">
      <h2>EDUCATION</h2>
      <div style="margin-bottom: 20px;">
        <span class="sub-head">Graduation</span>
        <table class="edu-table">
          <tr>
            <td class="edu-label">Course</td>
            <td>{{degree}}</td>
          </tr>
          <tr>
            <td class="edu-label">College</td>
            <td>{{college}}</td>
          </tr>
          <tr>
            <td class="edu-label">Score</td>
            <td>{{score}}</td>
          </tr>
        </table>
      </div>
      <div>
        <span class="sub-head" style="margin-bottom: 10px; display: block;">Schooling</span>
        <table class="edu-table" style="text-align: left;">
          <thead>
            <tr>
              <th style="width: 30%;"></th>
              <th style="width: 35%;">Class XII</th>
              <th style="width: 35%;">Class X</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="edu-label">Board Name</td>
              <td>{{twelfth_board}}</td>
              <td>{{tenth_board}}</td>
            </tr>
            <tr>
              <td class="edu-label">Medium</td>
              <td>{{twelfth_medium}}</td>
              <td>{{tenth_medium}}</td>
            </tr>
            <tr>
              <td class="edu-label">Year of Passing</td>
              <td>{{twelfth_year}}</td>
              <td>{{tenth_year}}</td>
            </tr>
            <tr>
              <td class="edu-label">Score</td>
              <td>{{twelfth_score}}</td>
              <td>{{tenth_score}}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class="right-section">
      <h2>INTERNSHIPS</h2>
      <div style="margin-bottom: 15px;">
        <span class="highlight">{{internship_title}} <span class="date-range">| {{internship_duration}}</span></span>
        <p style="margin-top: 5px;">{{internship_desc}}</p>
      </div>
    </div>
    <div class="right-section">
      <h2>PROJECTS</h2>
      <ul class="bullet-list">
        {{projects}}
      </ul>
    </div>
    <div class="right-section">
      <h2>WORK EXPERIENCE</h2>
      <div style="margin-bottom: 15px;">
        <span class="highlight">{{company}} <span class="date-range">| {{experience_duration}}</span></span>
        <p style="margin-top: 5px;">{{work_desc}}</p>
      </div>
    </div>
  </div>
</div>
</body>
</html>
''';
}
