# Under Construction — Disabled Links Reference

This document tracks all links and navigation elements that have been **temporarily disabled** while the site is under construction.

## How to Re-enable a Link

For each disabled element:

1. Remove the `disabled-link` class
2. Change `href="#"` back to `href="[value from data-href]"`
3. Delete the `data-href` attribute

## Global Navigation (app/views/shared/_header.html.erb)

### Main Nav
| Link Text | Original URL |
|---|---|
| The Retreat | `/the-retreat` |
| Experience | `/experience` |
| About | `/about` |
| Pages (dropdown) | — |
| └ FAQ | `/faq` |
| └ Policies | `/policies` |
| └ Privacy | `/privacy` |
| └ Terms | `/terms` |
| Book Your Stay | `/availability` |

### Sidebar Menu
| Link Text | Original URL |
|---|---|
| The Retreat | `/the-retreat` |
| Experience | `/experience` |
| About | `/about` |
| Info (dropdown) | — |
| └ FAQ | `/faq` |
| └ Policies | `/policies` |
| └ Privacy Policy | `/privacy` |
| └ Terms of Service | `/terms` |

## Footer (app/views/shared/_footer.html.erb)

### Top Links
| Link Text | Original URL |
|---|---|
| The Retreat | `/the-retreat` |
| Experience | `/experience` |
| About Us | `/about` |
| Availability | `/availability` |
| FAQ | `/faq` |

### Quick Links
| Link Text | Original URL |
|---|---|
| Policies | `/policies` |
| Privacy Policy | `/privacy` |
| Terms of Service | `/terms` |
| FAQ | `/faq` |

### Legal Links
| Link Text | Original URL |
|---|---|
| Privacy Policy | `/privacy` |
| Terms & Conditions | `/terms` |
| Cookies Policy | `/policies` |

## Home Page (app/views/pages/home.html.erb)

| Section | Button Text | Original URL |
|---|---|---|
| Hero | Check Availability | `/availability` |
| Property Overview | Explore the Property | `/the-retreat` |
| Experience Types | Learn More (Corporate) | `/experience#corporate` |
| Experience Types | Learn More (Wellness) | `/experience#wellness` |
| Experience Types | Learn More (Private) | `/experience#private` |
| Gallery | View All Photos | `/the-retreat#gallery` |
| Amenities | View All Amenities | `/the-retreat#amenities` |
| How It Works | Check Availability | `/availability` |
| CTA Section | View Availability | `/availability` |

## Still Active (Not Disabled)

These links on the home page still work:

- **Home** nav link — stays on current page
- **Take a Tour** button — scrolls to `#overview` on the same page
- **Phone number** — external call link
- **Logo** — links back to home page

## Password Protection

The entire site is password-protected via HTTP Basic Auth:

- **Username:** `anchorpoint`
- **Password:** `retreat2024`

To disable the password gate, remove `before_action :require_password` and the `require_password` method from `app/controllers/application_controller.rb`.
